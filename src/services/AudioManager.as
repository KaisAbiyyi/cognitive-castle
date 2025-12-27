package services {
    
    import flash.media.Sound;
    import flash.media.SoundChannel;
    import flash.media.SoundTransform;
    import flash.net.URLRequest;
    import flash.events.Event;
    import flash.events.IOErrorEvent;
    import flash.utils.Dictionary;
    
    /**
     * AudioManager - Centralized audio management service.
     * 
     * SOLID Principles:
     * - Single Responsibility: Manages all audio playback and volume control
     * - Open/Closed: Can extend with new audio types without modifying core
     * - Dependency Inversion: Services depend on this interface, not concrete implementations
     * 
     * Features:
     * - Sound effects (SFX) playback with volume control
     * - Background music (BGM) looping with volume control
     * - Repeating sound effects for continuous events
     * - Resource pooling to prevent memory leaks
     * - Defensive error handling for missing files
     * - Performance optimization through sound caching
     */
    public class AudioManager {
        
        // Debug mode
        private static const DEBUG:Boolean = true;
        
        // Volume constants
        private static const DEFAULT_SFX_VOLUME:Number = 0.30; // 30%
        private static const DEFAULT_BGM_VOLUME:Number = 0.25; // 25%
        private static const MIN_VOLUME:Number = 0.0;
        private static const MAX_VOLUME:Number = 1.0;
        
        // Audio paths (try multiple relative bases to avoid 2035 errors when assets aren't copied next to the SWF)
        private static const AUDIO_BASE_PATHS:Array = [
            "assets/audios/",
            "../assets/audios/",
            "../../assets/audios/"
        ];
        
        // Sound cache to prevent reloading
        private var _soundCache:Dictionary;
        
        // Active sound channels
        private var _activeSfxChannels:Array;
        private var _bgmChannel:SoundChannel;
        private var _repeatingSfxChannel:SoundChannel;
        
        // Current sounds
        private var _currentBgm:Sound;
        private var _currentRepeatingSfx:Sound;
        
        // Volume settings
        private var _sfxVolume:Number;
        private var _bgmVolume:Number;
        
        // Mute state
        private var _sfxMuted:Boolean = false;
        private var _bgmMuted:Boolean = false;
        
        // Repeating SFX state
        private var _repeatingSfxName:String = null;
        
        /**
         * Constructor
         */
        public function AudioManager() {
            _soundCache = new Dictionary();
            _activeSfxChannels = [];
            _sfxVolume = DEFAULT_SFX_VOLUME;
            _bgmVolume = DEFAULT_BGM_VOLUME;
            
            if (DEBUG) {
                trace("[AudioManager] Initialized with SFX=" + (_sfxVolume * 100) + "%, BGM=" + (_bgmVolume * 100) + "%");
            }
        }
        
        /**
         * Play a sound effect once
         * @param soundName Name of the sound file (without path and extension)
         * @param volumeMultiplier Optional volume multiplier (0-1), default uses SFX volume
         * @return true if played successfully, false otherwise
         */
        public function playSfx(soundName:String, volumeMultiplier:Number = 1.0):Boolean {
            if (!soundName || soundName.length == 0) {
                if (DEBUG) trace("[AudioManager] ERROR: Empty sound name provided");
                return false;
            }
            
            if (_sfxMuted) {
                if (DEBUG) trace("[AudioManager] SFX muted, skipping: " + soundName);
                return false;
            }
            
            // Validate volume multiplier
            volumeMultiplier = clampVolume(volumeMultiplier);
            
            var sound:Sound = loadSound(soundName);
            if (!sound) {
                return false;
            }
            
            try {
                var finalVolume:Number = _sfxVolume * volumeMultiplier;
                var transform:SoundTransform = new SoundTransform(finalVolume);
                var channel:SoundChannel = sound.play(0, 0, transform);
                
                if (channel) {
                    _activeSfxChannels.push(channel);
                    channel.addEventListener(Event.SOUND_COMPLETE, onSfxComplete);
                    
                    if (DEBUG) {
                        trace("[AudioManager] Playing SFX: " + soundName + " at " + (finalVolume * 100) + "%");
                    }
                    return true;
                } else {
                    if (DEBUG) trace("[AudioManager] WARNING: Could not create channel for: " + soundName);
                    return false;
                }
            } catch (error:Error) {
                if (DEBUG) {
                    trace("[AudioManager] ERROR playing SFX '" + soundName + "': " + error.message);
                }
                return false;
            }
            // Should never reach here, but compiler wants explicit return
            return false;
        }
        
        /**
         * Play background music in a loop
         * @param soundName Name of the BGM file (without path and extension)
         * @return true if started successfully, false otherwise
         */
        public function playBgm(soundName:String):Boolean {
            if (!soundName || soundName.length == 0) {
                if (DEBUG) trace("[AudioManager] ERROR: Empty BGM name provided");
                return false;
            }
            
            // Stop current BGM if playing
            stopBgm();
            
            if (_bgmMuted) {
                if (DEBUG) trace("[AudioManager] BGM muted, skipping: " + soundName);
                return false;
            }
            
            var sound:Sound = loadSound(soundName);
            if (!sound) {
                return false;
            }
            
            try {
                _currentBgm = sound;
                var transform:SoundTransform = new SoundTransform(_bgmVolume);
                _bgmChannel = sound.play(0, 0, transform);
                
                if (_bgmChannel) {
                    _bgmChannel.addEventListener(Event.SOUND_COMPLETE, onBgmComplete);
                    
                    if (DEBUG) {
                        trace("[AudioManager] Playing BGM: " + soundName + " at " + (_bgmVolume * 100) + "%");
                    }
                    return true;
                } else {
                    if (DEBUG) trace("[AudioManager] WARNING: Could not create BGM channel for: " + soundName);
                    return false;
                }
            } catch (error:Error) {
                if (DEBUG) {
                    trace("[AudioManager] ERROR playing BGM '" + soundName + "': " + error.message);
                }
                return false;
            }
            // Should never reach here, but compiler wants explicit return
            return false;
        }
        
        /**
         * Stop background music
         */
        public function stopBgm():void {
            if (_bgmChannel) {
                try {
                    _bgmChannel.stop();
                    _bgmChannel.removeEventListener(Event.SOUND_COMPLETE, onBgmComplete);
                } catch (error:Error) {
                    if (DEBUG) trace("[AudioManager] Error stopping BGM: " + error.message);
                }
                _bgmChannel = null;
            }
            _currentBgm = null;
            
            if (DEBUG) trace("[AudioManager] BGM stopped");
        }
        
        /**
         * Start playing a repeating sound effect
         * Used for continuous events like enemy attacking
         * @param soundName Name of the sound file
         * @param volumeMultiplier Optional volume multiplier
         * @return true if started successfully
         */
        public function startRepeatingSfx(soundName:String, volumeMultiplier:Number = 1.0):Boolean {
            if (!soundName || soundName.length == 0) {
                if (DEBUG) trace("[AudioManager] ERROR: Empty repeating SFX name");
                return false;
            }
            
            // Stop current repeating SFX if different
            if (_repeatingSfxName === soundName) {
                if (DEBUG) trace("[AudioManager] Repeating SFX already playing: " + soundName);
                return true;
            }
            
            stopRepeatingSfx();
            
            if (_sfxMuted) {
                if (DEBUG) trace("[AudioManager] SFX muted, skipping repeating: " + soundName);
                return false;
            }
            
            volumeMultiplier = clampVolume(volumeMultiplier);
            
            var sound:Sound = loadSound(soundName);
            if (!sound) {
                return false;
            }
            
            try {
                _currentRepeatingSfx = sound;
                _repeatingSfxName = soundName;
                
                var finalVolume:Number = _sfxVolume * volumeMultiplier;
                var transform:SoundTransform = new SoundTransform(finalVolume);
                _repeatingSfxChannel = sound.play(0, 0, transform);
                
                if (_repeatingSfxChannel) {
                    _repeatingSfxChannel.addEventListener(Event.SOUND_COMPLETE, onRepeatingSfxComplete);
                    
                    if (DEBUG) {
                        trace("[AudioManager] Started repeating SFX: " + soundName + " at " + (finalVolume * 100) + "%");
                    }
                    return true;
                } else {
                    if (DEBUG) trace("[AudioManager] WARNING: Could not create repeating channel for: " + soundName);
                    _repeatingSfxName = null;
                    return false;
                }
            } catch (error:Error) {
                if (DEBUG) {
                    trace("[AudioManager] ERROR starting repeating SFX '" + soundName + "': " + error.message);
                }
                _repeatingSfxName = null;
                return false;
            }
            // Should never reach here, but compiler wants explicit return
            return false;
        }
        
        /**
         * Stop repeating sound effect
         */
        public function stopRepeatingSfx():void {
            if (_repeatingSfxChannel) {
                try {
                    _repeatingSfxChannel.stop();
                    _repeatingSfxChannel.removeEventListener(Event.SOUND_COMPLETE, onRepeatingSfxComplete);
                } catch (error:Error) {
                    if (DEBUG) trace("[AudioManager] Error stopping repeating SFX: " + error.message);
                }
                _repeatingSfxChannel = null;
            }
            _currentRepeatingSfx = null;
            _repeatingSfxName = null;
            
            if (DEBUG) trace("[AudioManager] Repeating SFX stopped");
        }
        
        /**
         * Set SFX volume (0-1)
         */
        public function setSfxVolume(volume:Number):void {
            _sfxVolume = clampVolume(volume);
            
            // Update active SFX channels
            updateActiveSfxVolume();
            
            // Update repeating SFX
            if (_repeatingSfxChannel) {
                var transform:SoundTransform = _repeatingSfxChannel.soundTransform;
                transform.volume = _sfxVolume;
                _repeatingSfxChannel.soundTransform = transform;
            }
            
            if (DEBUG) {
                trace("[AudioManager] SFX volume set to " + (_sfxVolume * 100) + "%");
            }
        }
        
        /**
         * Set BGM volume (0-1)
         */
        public function setBgmVolume(volume:Number):void {
            _bgmVolume = clampVolume(volume);
            
            // Update BGM channel
            if (_bgmChannel) {
                var transform:SoundTransform = _bgmChannel.soundTransform;
                transform.volume = _bgmVolume;
                _bgmChannel.soundTransform = transform;
            }
            
            if (DEBUG) {
                trace("[AudioManager] BGM volume set to " + (_bgmVolume * 100) + "%");
            }
        }
        
        /**
         * Mute/unmute SFX
         */
        public function muteSfx(mute:Boolean):void {
            _sfxMuted = mute;
            
            if (mute) {
                // Stop all active SFX
                stopAllSfx();
                stopRepeatingSfx();
            }
            
            if (DEBUG) {
                trace("[AudioManager] SFX " + (mute ? "muted" : "unmuted"));
            }
        }
        
        /**
         * Mute/unmute BGM
         */
        public function muteBgm(mute:Boolean):void {
            _bgmMuted = mute;
            
            if (mute) {
                stopBgm();
            }
            
            if (DEBUG) {
                trace("[AudioManager] BGM " + (mute ? "muted" : "unmuted"));
            }
        }
        
        /**
         * Stop all sound effects
         */
        public function stopAllSfx():void {
            for each (var channel:SoundChannel in _activeSfxChannels) {
                if (channel) {
                    try {
                        channel.stop();
                        channel.removeEventListener(Event.SOUND_COMPLETE, onSfxComplete);
                    } catch (error:Error) {
                        // Ignore errors when stopping
                    }
                }
            }
            _activeSfxChannels = [];
            
            if (DEBUG) trace("[AudioManager] All SFX stopped");
        }
        
        /**
         * Stop all audio (SFX, BGM, repeating)
         */
        public function stopAll():void {
            stopAllSfx();
            stopRepeatingSfx();
            stopBgm();
            
            if (DEBUG) trace("[AudioManager] All audio stopped");
        }
        
        /**
         * Cleanup - stop all sounds and clear cache
         */
        public function dispose():void {
            stopAll();
            _soundCache = new Dictionary();
            
            if (DEBUG) trace("[AudioManager] Disposed");
        }
        
        // ========== GETTERS ==========
        
        public function get sfxVolume():Number { return _sfxVolume; }
        public function get bgmVolume():Number { return _bgmVolume; }
        public function get isSfxMuted():Boolean { return _sfxMuted; }
        public function get isBgmMuted():Boolean { return _bgmMuted; }
        public function get isPlayingBgm():Boolean { return _bgmChannel != null; }
        public function get isPlayingRepeatingSfx():Boolean { return _repeatingSfxChannel != null; }
        
        // ========== PRIVATE METHODS ==========
        
        /**
         * Load and cache a sound file
         */
        private function loadSound(soundName:String):Sound {
            // Check cache first
            if (_soundCache[soundName]) {
                return _soundCache[soundName] as Sound;
            }
            
            // Load new sound
            var sound:Sound = new Sound();
            var candidateIndex:int = 0;
            var attemptedPaths:Array = [];

            // Try multiple relative base paths so packaged builds can find assets regardless of copy location
            var ioErrorHandler:Function = null;
            ioErrorHandler = function(e:IOErrorEvent):void {
                candidateIndex++;
                if (candidateIndex < AUDIO_BASE_PATHS.length) {
                    var fallbackPath:String = AUDIO_BASE_PATHS[candidateIndex] + soundName + ".mp3";
                    attemptedPaths.push(fallbackPath);
                    try {
                        sound.load(new URLRequest(fallbackPath));
                    } catch (retryError:Error) {
                        if (DEBUG) {
                            trace("[AudioManager] ERROR retrying load for '" + soundName + "' at " + fallbackPath + ": " + retryError.message);
                        }
                    }
                } else {
                    sound.removeEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
                    if (DEBUG) {
                        trace("[AudioManager] ERROR loading sound '" + soundName + "'. Attempts: " + attemptedPaths.join(", ") + " | " + e.text);
                    }
                }
            };

            try {
                var initialPath:String = AUDIO_BASE_PATHS[0] + soundName + ".mp3";
                attemptedPaths.push(initialPath);
                sound.addEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
                sound.load(new URLRequest(initialPath));
                _soundCache[soundName] = sound;
                
                if (DEBUG) {
                    trace("[AudioManager] Loading sound: " + initialPath);
                }
                
                return sound;
            } catch (error:Error) {
                sound.removeEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
                if (DEBUG) {
                    trace("[AudioManager] ERROR creating sound for '" + soundName + "': " + error.message);
                }
                return null;
            }
            // Should never reach here, but compiler wants explicit return
            return null;
        }
        
        /**
         * Clamp volume to valid range
         */
        private function clampVolume(volume:Number):Number {
            if (isNaN(volume)) return DEFAULT_SFX_VOLUME;
            return Math.max(MIN_VOLUME, Math.min(MAX_VOLUME, volume));
        }
        
        /**
         * Update volume for all active SFX channels
         */
        private function updateActiveSfxVolume():void {
            for each (var channel:SoundChannel in _activeSfxChannels) {
                if (channel) {
                    try {
                        var transform:SoundTransform = channel.soundTransform;
                        transform.volume = _sfxVolume;
                        channel.soundTransform = transform;
                    } catch (error:Error) {
                        // Channel might have completed, ignore
                    }
                }
            }
        }
        
        /**
         * Handle SFX completion
         */
        private function onSfxComplete(event:Event):void {
            var channel:SoundChannel = event.target as SoundChannel;
            if (channel) {
                channel.removeEventListener(Event.SOUND_COMPLETE, onSfxComplete);
                
                // Remove from active channels
                var index:int = _activeSfxChannels.indexOf(channel);
                if (index >= 0) {
                    _activeSfxChannels.splice(index, 1);
                }
            }
        }
        
        /**
         * Handle BGM completion - restart loop
         */
        private function onBgmComplete(event:Event):void {
            if (_currentBgm && !_bgmMuted) {
                try {
                    var transform:SoundTransform = new SoundTransform(_bgmVolume);
                    _bgmChannel = _currentBgm.play(0, 0, transform);
                    
                    if (_bgmChannel) {
                        _bgmChannel.addEventListener(Event.SOUND_COMPLETE, onBgmComplete);
                        
                        if (DEBUG) {
                            trace("[AudioManager] BGM looped");
                        }
                    }
                } catch (error:Error) {
                    if (DEBUG) {
                        trace("[AudioManager] ERROR looping BGM: " + error.message);
                    }
                }
            }
        }
        
        /**
         * Handle repeating SFX completion - restart immediately
         */
        private function onRepeatingSfxComplete(event:Event):void {
            if (_currentRepeatingSfx && !_sfxMuted && _repeatingSfxName) {
                try {
                    var transform:SoundTransform = new SoundTransform(_sfxVolume);
                    _repeatingSfxChannel = _currentRepeatingSfx.play(0, 0, transform);
                    
                    if (_repeatingSfxChannel) {
                        _repeatingSfxChannel.addEventListener(Event.SOUND_COMPLETE, onRepeatingSfxComplete);
                    }
                } catch (error:Error) {
                    if (DEBUG) {
                        trace("[AudioManager] ERROR repeating SFX: " + error.message);
                    }
                    _repeatingSfxName = null;
                }
            }
        }
    }
}
    import flash.media.Sound;
    import flash.net.URLRequest;
    import flash.media.SoundChannel;
    import flash.media.SoundTransform;
    import flash.media.SoundMixer;
    import flash.events.EventDispatcher;
    import flash.events.Event;
    import flash.events.IOErrorEvent;

    public class AudioManager extends EventDispatcher {
        private static var _instance:AudioManager;
        public var masterVolume:Number = 1.0;
        
        private var _sounds:Object = {};
        private var _musicChannel:SoundChannel;
        private var _currentMusicName:String = "";

        public static function getInstance():AudioManager {
            return _instance ||= new AudioManager();
        }

        public function init():void {
            loadSound("ButtonIn", "assets/Audio/ButtonIn.mpeg");
            loadSound("ButtonOut", "assets/Audio/ButtonOut.mpeg");
            loadSound("Bgmlobby", "assets/Audio/Bgmlobby.mp3");
            setMasterLevel(10);
        }

        public function loadSound(name:String, url:String):void {
            var s:Sound = new Sound();
            s.addEventListener(Event.COMPLETE, function(e:Event):void { dispatchEvent(new Event("soundLoaded")); });
            s.addEventListener(IOErrorEvent.IO_ERROR, function(e:IOErrorEvent):void { trace("[Audio] Gagal: " + name); });
            try { s.load(new URLRequest(url)); _sounds[name] = s; } 
            catch(e:Error) { trace("[Audio] Error: " + e.message); }
        }

        public function isSoundLoaded(name:String):Boolean { return _sounds[name] != null; }

        public function play(name:String, startTime:Number = 0, loops:int = 0):SoundChannel {
            if (name == "Bgmlobby") { playMusic(name); return _musicChannel; }
            var s:Sound = _sounds[name] as Sound;
            return (s) ? s.play(startTime, loops, new SoundTransform(masterVolume)) : null;
        }

        public function playMusic(name:String):void {
            if (_currentMusicName == name && _musicChannel) return; // Sudah main
            stopMusic();
            
            var s:Sound = _sounds[name] as Sound;
            if (s) {
                _musicChannel = s.play(0, 9999, new SoundTransform(masterVolume));
                _currentMusicName = name;
            }
        }

        public function stopMusic():void {
            if (_musicChannel) { _musicChannel.stop(); _musicChannel = null; }
            _currentMusicName = "";
        }

        public function setMusicVolume(volume:Number):void {
            if (_musicChannel) _musicChannel.soundTransform = new SoundTransform(Math.max(0, Math.min(1, volume)));
        }

        public function getMusicVolume():Number {
            return (_musicChannel) ? _musicChannel.soundTransform.volume : masterVolume;
        }

        public function stopAll():void {
            SoundMixer.stopAll();
            _musicChannel = null; 
            _currentMusicName = "";
        }

        public function setMasterLevel(level:int):void {
            masterVolume = Math.max(0, Math.min(10, level)) / 10.0;
            SoundMixer.soundTransform = new SoundTransform(masterVolume);
            if (_musicChannel) _musicChannel.soundTransform = new SoundTransform(masterVolume);
        }
    }
}
