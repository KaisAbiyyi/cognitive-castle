package services {
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