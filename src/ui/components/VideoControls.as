package ui.components {
    import flash.display.*;
    import flash.events.*;
    import flash.net.NetStream;
    import flash.text.*;
    import flash.utils.Timer;
    
    /**
     * VideoControls - YouTube-style video player controls
     * Features: Play/Pause button, Seek/Scrubber progress bar, Time display
     */
    public class VideoControls extends Sprite {
        
        // Events
        public static const PLAY_CLICKED:String = "playClicked";
        public static const PAUSE_CLICKED:String = "pauseClicked";
        public static const SEEK:String = "seek";
        
        // UI Components
        private var _controlBar:Sprite;
        private var _playPauseBtn:Sprite;
        private var _progressBar:Sprite;
        private var _progressTrack:Shape;
        private var _progressFill:Shape;
        private var _progressBuffer:Shape;
        private var _progressKnob:Sprite;
        private var _timeDisplay:TextField;
        private var _durationDisplay:TextField;
        
        // State
        private var _isPlaying:Boolean = false;
        private var _duration:Number = 0;
        private var _currentTime:Number = 0;
        private var _seekPosition:Number = 0;
        private var _isDragging:Boolean = false;
        private var _netStream:NetStream;
        
        // Dimensions
        private var _width:Number;
        private var _height:Number = 50;
        private var _barHeight:Number = 6;
        private var _knobRadius:Number = 8;
        private var _btnSize:Number = 36;
        
        // Update timer
        private var _updateTimer:Timer;
        
        // Auto-hide
        private var _autoHideTimer:Timer;
        private var _autoHideEnabled:Boolean = true;
        private var _isVisible:Boolean = true;
        
        public function VideoControls(width:Number) {
            _width = width;
            createUI();
            startUpdateTimer();
        }
        
        private function createUI():void {
            // Control bar background
            _controlBar = new Sprite();
            _controlBar.graphics.beginFill(0x000000, 0.7);
            _controlBar.graphics.drawRoundRect(0, 0, _width, _height, 8, 8);
            _controlBar.graphics.endFill();
            addChild(_controlBar);
            
            // Play/Pause button
            _playPauseBtn = new Sprite();
            _playPauseBtn.buttonMode = true;
            _playPauseBtn.x = 15;
            _playPauseBtn.y = (_height - _btnSize) / 2;
            drawPlayIcon();
            _playPauseBtn.addEventListener(MouseEvent.CLICK, onPlayPauseClick);
            _playPauseBtn.addEventListener(MouseEvent.MOUSE_OVER, onBtnOver);
            _playPauseBtn.addEventListener(MouseEvent.MOUSE_OUT, onBtnOut);
            _controlBar.addChild(_playPauseBtn);
            
            // Time display (current)
            _timeDisplay = createTimeField();
            _timeDisplay.x = 60;
            _timeDisplay.y = (_height - 20) / 2;
            _timeDisplay.text = "0:00";
            _controlBar.addChild(_timeDisplay);
            
            // Duration display
            _durationDisplay = createTimeField();
            _durationDisplay.x = _width - 60;
            _durationDisplay.y = (_height - 20) / 2;
            _durationDisplay.text = "0:00";
            _controlBar.addChild(_durationDisplay);
            
            // Progress bar container
            _progressBar = new Sprite();
            _progressBar.x = 110;
            _progressBar.y = (_height - _barHeight) / 2;
            _controlBar.addChild(_progressBar);
            
            var progressWidth:Number = _width - 180;
            
            // Progress track (background)
            _progressTrack = new Shape();
            _progressTrack.graphics.beginFill(0x555555, 0.8);
            _progressTrack.graphics.drawRoundRect(0, 0, progressWidth, _barHeight, _barHeight, _barHeight);
            _progressTrack.graphics.endFill();
            _progressBar.addChild(_progressTrack);
            
            // Progress buffer (loaded portion)
            _progressBuffer = new Shape();
            _progressBar.addChild(_progressBuffer);
            
            // Progress fill (played portion)
            _progressFill = new Shape();
            _progressBar.addChild(_progressFill);
            
            // Progress knob
            _progressKnob = new Sprite();
            _progressKnob.graphics.beginFill(0xFFFFFF);
            _progressKnob.graphics.drawCircle(0, _barHeight / 2, _knobRadius);
            _progressKnob.graphics.endFill();
            _progressKnob.buttonMode = true;
            _progressKnob.y = 0;
            _progressBar.addChild(_progressKnob);
            
            // Progress bar interaction
            _progressBar.addEventListener(MouseEvent.MOUSE_DOWN, onProgressMouseDown);
            
            // Initial draw
            updateProgressBar(0);
            
            // Auto-hide setup
            setupAutoHide();
        }
        
        private function createTimeField():TextField {
            var tf:TextField = new TextField();
            tf.defaultTextFormat = new TextFormat("Arial", 12, 0xFFFFFF, true);
            tf.autoSize = TextFieldAutoSize.LEFT;
            tf.selectable = false;
            tf.mouseEnabled = false;
            return tf;
        }
        
        private function drawPlayIcon():void {
            _playPauseBtn.graphics.clear();
            // Background circle
            _playPauseBtn.graphics.beginFill(0x4A90E2, 0.9);
            _playPauseBtn.graphics.drawCircle(_btnSize / 2, _btnSize / 2, _btnSize / 2);
            _playPauseBtn.graphics.endFill();
            // Play triangle
            _playPauseBtn.graphics.beginFill(0xFFFFFF);
            _playPauseBtn.graphics.moveTo(_btnSize * 0.38, _btnSize * 0.25);
            _playPauseBtn.graphics.lineTo(_btnSize * 0.38, _btnSize * 0.75);
            _playPauseBtn.graphics.lineTo(_btnSize * 0.72, _btnSize * 0.5);
            _playPauseBtn.graphics.lineTo(_btnSize * 0.38, _btnSize * 0.25);
            _playPauseBtn.graphics.endFill();
        }
        
        private function drawPauseIcon():void {
            _playPauseBtn.graphics.clear();
            // Background circle
            _playPauseBtn.graphics.beginFill(0x4A90E2, 0.9);
            _playPauseBtn.graphics.drawCircle(_btnSize / 2, _btnSize / 2, _btnSize / 2);
            _playPauseBtn.graphics.endFill();
            // Pause bars
            _playPauseBtn.graphics.beginFill(0xFFFFFF);
            _playPauseBtn.graphics.drawRoundRect(_btnSize * 0.3, _btnSize * 0.25, _btnSize * 0.15, _btnSize * 0.5, 2, 2);
            _playPauseBtn.graphics.drawRoundRect(_btnSize * 0.55, _btnSize * 0.25, _btnSize * 0.15, _btnSize * 0.5, 2, 2);
            _playPauseBtn.graphics.endFill();
        }
        
        private function onPlayPauseClick(e:MouseEvent):void {
            if (_isPlaying) {
                pause();
                dispatchEvent(new Event(PAUSE_CLICKED));
            } else {
                play();
                dispatchEvent(new Event(PLAY_CLICKED));
            }
        }
        
        private function onBtnOver(e:MouseEvent):void {
            _playPauseBtn.scaleX = _playPauseBtn.scaleY = 1.1;
            _playPauseBtn.x = 15 - (_btnSize * 0.05);
            _playPauseBtn.y = (_height - _btnSize) / 2 - (_btnSize * 0.05);
        }
        
        private function onBtnOut(e:MouseEvent):void {
            _playPauseBtn.scaleX = _playPauseBtn.scaleY = 1.0;
            _playPauseBtn.x = 15;
            _playPauseBtn.y = (_height - _btnSize) / 2;
        }
        
        private function onProgressMouseDown(e:MouseEvent):void {
            _isDragging = true;
            updateSeekPosition(e);
            if (stage) {
                stage.addEventListener(MouseEvent.MOUSE_MOVE, onProgressDrag);
                stage.addEventListener(MouseEvent.MOUSE_UP, onProgressMouseUp);
            }
        }
        
        private function onProgressDrag(e:MouseEvent):void {
            if (_isDragging) {
                updateSeekPosition(e);
            }
        }
        
        private function onProgressMouseUp(e:MouseEvent):void {
            if (_isDragging) {
                _isDragging = false;
                // Seek to position
                if (_netStream && _duration > 0) {
                    var seekTime:Number = _seekPosition * _duration;
                    _netStream.seek(seekTime);
                    _currentTime = seekTime;
                }
                dispatchEvent(new Event(SEEK));
            }
            if (stage) {
                stage.removeEventListener(MouseEvent.MOUSE_MOVE, onProgressDrag);
                stage.removeEventListener(MouseEvent.MOUSE_UP, onProgressMouseUp);
            }
        }
        
        private function updateSeekPosition(e:MouseEvent):void {
            var progressWidth:Number = _width - 180;
            var localX:Number = _progressBar.globalToLocal(new flash.geom.Point(e.stageX, e.stageY)).x;
            _seekPosition = Math.max(0, Math.min(1, localX / progressWidth));
            updateProgressBar(_seekPosition);
        }
        
        private function updateProgressBar(progress:Number):void {
            var progressWidth:Number = _width - 180;
            var fillWidth:Number = progress * progressWidth;
            
            _progressFill.graphics.clear();
            _progressFill.graphics.beginFill(0x4A90E2);
            _progressFill.graphics.drawRoundRect(0, 0, Math.max(1, fillWidth), _barHeight, _barHeight, _barHeight);
            _progressFill.graphics.endFill();
            
            _progressKnob.x = fillWidth;
        }
        
        private function updateBufferBar(bufferProgress:Number):void {
            var progressWidth:Number = _width - 180;
            var bufferWidth:Number = bufferProgress * progressWidth;
            
            _progressBuffer.graphics.clear();
            _progressBuffer.graphics.beginFill(0x888888, 0.5);
            _progressBuffer.graphics.drawRoundRect(0, 0, Math.max(1, bufferWidth), _barHeight, _barHeight, _barHeight);
            _progressBuffer.graphics.endFill();
        }
        
        private function startUpdateTimer():void {
            _updateTimer = new Timer(100);
            _updateTimer.addEventListener(TimerEvent.TIMER, onUpdateTimer);
            _updateTimer.start();
        }
        
        private function onUpdateTimer(e:TimerEvent):void {
            if (_netStream && !_isDragging) {
                _currentTime = _netStream.time;
                if (_duration > 0) {
                    var progress:Number = _currentTime / _duration;
                    updateProgressBar(progress);
                    
                    // Update buffer
                    var bufferProgress:Number = (_currentTime + _netStream.bufferLength) / _duration;
                    updateBufferBar(Math.min(1, bufferProgress));
                }
                _timeDisplay.text = formatTime(_currentTime);
            }
        }
        
        private function formatTime(seconds:Number):String {
            if (isNaN(seconds) || seconds < 0) seconds = 0;
            var mins:int = Math.floor(seconds / 60);
            var secs:int = Math.floor(seconds % 60);
            return mins + ":" + (secs < 10 ? "0" : "") + secs;
        }
        
        // Auto-hide functionality
        private function setupAutoHide():void {
            _autoHideTimer = new Timer(3000, 1);
            _autoHideTimer.addEventListener(TimerEvent.TIMER_COMPLETE, onAutoHide);
            
            addEventListener(MouseEvent.MOUSE_OVER, onControlsOver);
            addEventListener(MouseEvent.MOUSE_OUT, onControlsOut);
        }
        
        private function onControlsOver(e:MouseEvent):void {
            _autoHideTimer.reset();
            showControls();
        }
        
        private function onControlsOut(e:MouseEvent):void {
            if (_autoHideEnabled && _isPlaying) {
                _autoHideTimer.reset();
                _autoHideTimer.start();
            }
        }
        
        private function onAutoHide(e:TimerEvent):void {
            if (_autoHideEnabled && _isPlaying) {
                hideControls();
            }
        }
        
        private function showControls():void {
            if (!_isVisible) {
                _isVisible = true;
                _controlBar.alpha = 1;
            }
        }
        
        private function hideControls():void {
            if (_isVisible) {
                _isVisible = false;
                _controlBar.alpha = 0.3;
            }
        }
        
        // Public methods
        public function setNetStream(ns:NetStream):void {
            _netStream = ns;
        }
        
        public function setDuration(duration:Number):void {
            _duration = duration;
            _durationDisplay.text = formatTime(duration);
        }
        
        public function play():void {
            _isPlaying = true;
            drawPauseIcon();
            if (_netStream) {
                _netStream.resume();
            }
        }
        
        public function pause():void {
            _isPlaying = false;
            drawPlayIcon();
            if (_netStream) {
                _netStream.pause();
            }
            showControls();
        }
        
        public function get isPlaying():Boolean {
            return _isPlaying;
        }
        
        public function get currentTime():Number {
            return _currentTime;
        }
        
        public function get seekPosition():Number {
            return _seekPosition;
        }
        
        public function setAutoHide(enabled:Boolean):void {
            _autoHideEnabled = enabled;
            if (!enabled) {
                showControls();
            }
        }
        
        public function reset():void {
            _currentTime = 0;
            _seekPosition = 0;
            _isPlaying = false;
            drawPlayIcon();
            updateProgressBar(0);
            updateBufferBar(0);
            _timeDisplay.text = "0:00";
            _durationDisplay.text = "0:00";
            showControls();
        }
        
        public function dispose():void {
            if (_updateTimer) {
                _updateTimer.stop();
                _updateTimer.removeEventListener(TimerEvent.TIMER, onUpdateTimer);
                _updateTimer = null;
            }
            if (_autoHideTimer) {
                _autoHideTimer.stop();
                _autoHideTimer.removeEventListener(TimerEvent.TIMER_COMPLETE, onAutoHide);
                _autoHideTimer = null;
            }
            if (stage) {
                stage.removeEventListener(MouseEvent.MOUSE_MOVE, onProgressDrag);
                stage.removeEventListener(MouseEvent.MOUSE_UP, onProgressMouseUp);
            }
            _netStream = null;
        }
    }
}
