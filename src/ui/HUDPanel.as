package ui {
    
    import flash.display.Sprite;
    import flash.display.Shape;
    import flash.display.Graphics;
    import flash.text.TextField;
    import flash.text.TextFormat;
    import flash.text.TextFormatAlign;
    import flash.events.Event;
    import flash.events.TimerEvent;
    import flash.utils.Timer;
    import flash.filters.GlowFilter;
    import flash.filters.BlurFilter;
    
    /**
     * HUDPanel - Enhanced HUD component with animated elements.
     * Features: Animated score counter, streak fire effect, timer bar, castle progress.
     * 
     * T1-076, T1-077
     */
    public class HUDPanel extends Sprite {
        
        // ============ VISUAL ELEMENTS ============
        
        // Score display
        private var _scoreContainer:Sprite;
        private var _scoreLabel:TextField;
        private var _scoreValue:TextField;
        private var _displayedScore:int = 0;
        private var _targetScore:int = 0;
        
        // Level indicator
        private var _levelContainer:Sprite;
        private var _levelLabel:TextField;
        private var _levelValue:TextField;
        private var _spanValue:TextField;
        
        // Streak counter with fire effect
        private var _streakContainer:Sprite;
        private var _streakLabel:TextField;
        private var _streakValue:TextField;
        private var _streakFlames:Array;
        private var _currentStreak:int = 0;
        
        // Timer bar
        private var _timerContainer:Sprite;
        private var _timerBarBg:Shape;
        private var _timerBar:Shape;
        private var _timerText:TextField;
        private var _timerProgress:Number = 1.0;
        
        // Castle progress bar
        private var _castleContainer:Sprite;
        private var _castleProgressBg:Shape;
        private var _castleProgressBar:Shape;
        private var _castleLabel:TextField;
        private var _castleMilestone:TextField;
        private var _castleProgress:Number = 0;
        
        // State indicator
        private var _stateContainer:Sprite;
        private var _stateBg:Shape;
        private var _stateText:TextField;
        private var _stateColors:Object;
        
        // Mini castle preview
        private var _miniCastleContainer:Sprite;
        
        // Layout
        private var _stageWidth:Number;
        private var _stageHeight:Number;
        private var _padding:int = 20;
        
        // Animation
        private var _animationTimer:Timer;
        private var _flamePhase:Number = 0;
        
        /**
         * Constructor
         */
        public function HUDPanel() {
            _streakFlames = [];
            _stateColors = {
                "READY": 0x4CAF50,
                "WATCH": 0x2196F3,
                "ANSWER": 0xFFEB3B,
                "RESULT": 0x9C27B0
            };
            
            createScoreDisplay();
            createLevelDisplay();
            createStreakDisplay();
            createTimerBar();
            createCastleProgress();
            createStateIndicator();
            createMiniCastle();
            
            // Start animation loop
            addEventListener(Event.ENTER_FRAME, onEnterFrame);
        }
        
        /**
         * Initialize with dimensions
         */
        public function initialize(stageWidth:Number, stageHeight:Number):void {
            _stageWidth = stageWidth;
            _stageHeight = stageHeight;
            layoutComponents();
        }
        
        // ============ CREATE COMPONENTS ============
        
        private function createScoreDisplay():void {
            _scoreContainer = new Sprite();
            addChild(_scoreContainer);
            
            // Background
            var bg:Shape = new Shape();
            bg.graphics.beginFill(0x1A1A2E, 0.9);
            bg.graphics.drawRoundRect(0, 0, 150, 50, 10, 10);
            bg.graphics.endFill();
            _scoreContainer.addChild(bg);
            
            // Label
            _scoreLabel = createTextField("SCORE", 12, 0xAAAAAA);
            _scoreLabel.x = 10;
            _scoreLabel.y = 5;
            _scoreContainer.addChild(_scoreLabel);
            
            // Value
            _scoreValue = createTextField("0", 24, 0xFFFFFF, true);
            _scoreValue.x = 10;
            _scoreValue.y = 20;
            _scoreContainer.addChild(_scoreValue);
        }
        
        private function createLevelDisplay():void {
            _levelContainer = new Sprite();
            addChild(_levelContainer);
            
            // Background
            var bg:Shape = new Shape();
            bg.graphics.beginFill(0x1A1A2E, 0.9);
            bg.graphics.drawRoundRect(0, 0, 120, 50, 10, 10);
            bg.graphics.endFill();
            _levelContainer.addChild(bg);
            
            // Label
            _levelLabel = createTextField("LEVEL", 12, 0xAAAAAA);
            _levelLabel.x = 10;
            _levelLabel.y = 5;
            _levelContainer.addChild(_levelLabel);
            
            // Level value
            _levelValue = createTextField("1", 20, 0xFFFFFF, true);
            _levelValue.x = 10;
            _levelValue.y = 20;
            _levelContainer.addChild(_levelValue);
            
            // Span value
            _spanValue = createTextField("Span: 3", 14, 0x888888);
            _spanValue.x = 50;
            _spanValue.y = 25;
            _levelContainer.addChild(_spanValue);
        }
        
        private function createStreakDisplay():void {
            _streakContainer = new Sprite();
            addChild(_streakContainer);
            
            // Background
            var bg:Shape = new Shape();
            bg.graphics.beginFill(0x1A1A2E, 0.9);
            bg.graphics.drawRoundRect(0, 0, 100, 50, 10, 10);
            bg.graphics.endFill();
            _streakContainer.addChild(bg);
            
            // Flame particles (created dynamically)
            for (var i:int = 0; i < 5; i++) {
                var flame:Shape = new Shape();
                flame.visible = false;
                _streakContainer.addChild(flame);
                _streakFlames.push(flame);
            }
            
            // Label
            _streakLabel = createTextField("STREAK", 12, 0xAAAAAA);
            _streakLabel.x = 10;
            _streakLabel.y = 5;
            _streakContainer.addChild(_streakLabel);
            
            // Value
            _streakValue = createTextField("0", 24, 0xFFFFFF, true);
            _streakValue.x = 10;
            _streakValue.y = 20;
            _streakContainer.addChild(_streakValue);
        }
        
        private function createTimerBar():void {
            _timerContainer = new Sprite();
            _timerContainer.visible = false;
            addChild(_timerContainer);
            
            // Background bar
            _timerBarBg = new Shape();
            _timerBarBg.graphics.beginFill(0x333355, 0.8);
            _timerBarBg.graphics.drawRoundRect(0, 0, 300, 24, 12, 12);
            _timerBarBg.graphics.endFill();
            _timerContainer.addChild(_timerBarBg);
            
            // Progress bar
            _timerBar = new Shape();
            _timerContainer.addChild(_timerBar);
            
            // Time text
            _timerText = createTextField("10s", 14, 0xFFFFFF, true);
            _timerText.width = 300;
            _timerContainer.addChild(_timerText);
        }
        
        private function createCastleProgress():void {
            _castleContainer = new Sprite();
            addChild(_castleContainer);
            
            // Background
            var bg:Shape = new Shape();
            bg.graphics.beginFill(0x1A1A2E, 0.9);
            bg.graphics.drawRoundRect(0, 0, 200, 60, 10, 10);
            bg.graphics.endFill();
            _castleContainer.addChild(bg);
            
            // Label
            _castleLabel = createTextField("CASTLE PROGRESS", 12, 0xAAAAAA);
            _castleLabel.x = 10;
            _castleLabel.y = 5;
            _castleContainer.addChild(_castleLabel);
            
            // Progress bar background
            _castleProgressBg = new Shape();
            _castleProgressBg.graphics.beginFill(0x333355);
            _castleProgressBg.graphics.drawRoundRect(10, 25, 180, 12, 6, 6);
            _castleProgressBg.graphics.endFill();
            _castleContainer.addChild(_castleProgressBg);
            
            // Progress bar
            _castleProgressBar = new Shape();
            _castleContainer.addChild(_castleProgressBar);
            
            // Milestone text
            _castleMilestone = createTextField("Foundation", 12, 0x888888);
            _castleMilestone.x = 10;
            _castleMilestone.y = 42;
            _castleContainer.addChild(_castleMilestone);
        }
        
        private function createStateIndicator():void {
            _stateContainer = new Sprite();
            addChild(_stateContainer);
            
            // Background
            _stateBg = new Shape();
            _stateContainer.addChild(_stateBg);
            
            // State text
            _stateText = createTextField("READY", 20, 0xFFFFFF, true);
            _stateText.width = 150;
            _stateContainer.addChild(_stateText);
            
            updateStateIndicator("READY");
        }
        
        private function createMiniCastle():void {
            _miniCastleContainer = new Sprite();
            _miniCastleContainer.visible = false; // Enable when castle preview is ready
            addChild(_miniCastleContainer);
            
            // Placeholder mini castle
            var castle:Shape = new Shape();
            castle.graphics.beginFill(0x888888);
            castle.graphics.drawRect(0, 0, 50, 50);
            castle.graphics.endFill();
            _miniCastleContainer.addChild(castle);
        }
        
        // ============ LAYOUT ============
        
        private function layoutComponents():void {
            // Score - top left
            _scoreContainer.x = _padding;
            _scoreContainer.y = _padding;
            
            // Level - next to score
            _levelContainer.x = _scoreContainer.x + 160;
            _levelContainer.y = _padding;
            
            // Streak - next to level
            _streakContainer.x = _levelContainer.x + 130;
            _streakContainer.y = _padding;
            
            // Castle progress - top right
            _castleContainer.x = _stageWidth - 200 - _padding;
            _castleContainer.y = _padding;
            
            // State indicator - center top
            _stateContainer.x = (_stageWidth - 150) / 2;
            _stateContainer.y = _padding;
            
            // Timer bar - center, below state
            _timerContainer.x = (_stageWidth - 300) / 2;
            _timerContainer.y = 80;
            
            // Mini castle - bottom right
            _miniCastleContainer.x = _stageWidth - 70;
            _miniCastleContainer.y = _stageHeight - 70;
        }
        
        // ============ UPDATE METHODS ============
        
        /**
         * Set score with animation
         */
        public function setScore(score:int, animate:Boolean = true):void {
            _targetScore = score;
            
            if (!animate) {
                _displayedScore = score;
                _scoreValue.text = String(score);
            }
            // Animation happens in onEnterFrame
        }
        
        /**
         * Set level
         */
        public function setLevel(level:int, span:int):void {
            _levelValue.text = String(level);
            _spanValue.text = "Span: " + span;
        }
        
        /**
         * Set streak with fire effect
         */
        public function setStreak(streak:int):void {
            var prevStreak:int = _currentStreak;
            _currentStreak = streak;
            _streakValue.text = String(streak);
            
            // Update fire effect visibility
            updateFireEffect(streak);
            
            // Flash effect if streak increased
            if (streak > prevStreak && streak >= 3) {
                flashStreak();
            }
        }
        
        /**
         * Show/hide timer and update progress
         */
        public function showTimer(show:Boolean):void {
            _timerContainer.visible = show;
        }
        
        public function updateTimer(remainingMs:int, totalMs:int):void {
            _timerProgress = remainingMs / totalMs;
            
            var seconds:Number = Math.ceil(remainingMs / 1000);
            _timerText.text = seconds + "s";
            
            // Color based on time
            var barColor:uint;
            if (seconds <= 3) {
                barColor = 0xF44336; // Red
            } else if (seconds <= 5) {
                barColor = 0xFF9800; // Orange
            } else {
                barColor = 0x4CAF50; // Green
            }
            
            // Draw progress bar
            var barWidth:Number = 296 * _timerProgress;
            _timerBar.graphics.clear();
            _timerBar.graphics.beginFill(barColor);
            _timerBar.graphics.drawRoundRect(2, 2, barWidth, 20, 10, 10);
            _timerBar.graphics.endFill();
        }
        
        /**
         * Update castle progress
         */
        public function setCastleProgress(progress:Number, milestone:String):void {
            _castleProgress = Math.max(0, Math.min(1, progress));
            _castleMilestone.text = milestone;
            
            // Draw progress bar
            var barWidth:Number = 176 * _castleProgress;
            _castleProgressBar.graphics.clear();
            _castleProgressBar.graphics.beginFill(0x4CAF50);
            _castleProgressBar.graphics.drawRoundRect(12, 26, barWidth, 10, 5, 5);
            _castleProgressBar.graphics.endFill();
        }
        
        /**
         * Update state indicator
         */
        public function setState(state:String):void {
            updateStateIndicator(state);
        }
        
        private function updateStateIndicator(state:String):void {
            var color:uint = _stateColors[state] || 0x888888;
            
            _stateBg.graphics.clear();
            _stateBg.graphics.beginFill(color, 0.9);
            _stateBg.graphics.drawRoundRect(0, 0, 150, 40, 10, 10);
            _stateBg.graphics.endFill();
            
            _stateText.text = state;
            _stateText.y = 10;
            
            // Add glow
            _stateContainer.filters = [new GlowFilter(color, 0.5, 10, 10, 1)];
        }
        
        // ============ ANIMATIONS ============
        
        private function onEnterFrame(e:Event):void {
            // Animate score counting
            if (_displayedScore != _targetScore) {
                var diff:int = _targetScore - _displayedScore;
                var step:int = Math.ceil(Math.abs(diff) / 10);
                if (step < 1) step = 1;
                
                if (diff > 0) {
                    _displayedScore += step;
                    if (_displayedScore > _targetScore) _displayedScore = _targetScore;
                } else {
                    _displayedScore -= step;
                    if (_displayedScore < _targetScore) _displayedScore = _targetScore;
                }
                
                _scoreValue.text = String(_displayedScore);
            }
            
            // Animate fire effect
            if (_currentStreak >= 3) {
                _flamePhase += 0.1;
                animateFlames();
            }
        }
        
        private function updateFireEffect(streak:int):void {
            var showFlames:Boolean = streak >= 3;
            
            for (var i:int = 0; i < _streakFlames.length; i++) {
                _streakFlames[i].visible = showFlames && i < Math.min(streak - 2, 5);
            }
            
            // Streak color based on level
            if (streak >= 10) {
                _streakValue.textColor = 0xFF4444; // Red hot
            } else if (streak >= 5) {
                _streakValue.textColor = 0xFFAA00; // Orange
            } else if (streak >= 3) {
                _streakValue.textColor = 0xFFFF00; // Yellow
            } else {
                _streakValue.textColor = 0xFFFFFF; // White
            }
        }
        
        private function animateFlames():void {
            for (var i:int = 0; i < _streakFlames.length; i++) {
                if (!_streakFlames[i].visible) continue;
                
                var flame:Shape = _streakFlames[i];
                flame.graphics.clear();
                
                // Animated flame position and size
                var flameY:Number = 35 - Math.sin(_flamePhase + i * 0.5) * 5;
                var flameHeight:Number = 12 + Math.sin(_flamePhase * 2 + i) * 4;
                var flameX:Number = 75 + i * 5;
                
                // Draw flame (simple triangle for now)
                var flameColor:uint = (i % 2 == 0) ? 0xFF6600 : 0xFFAA00;
                flame.graphics.beginFill(flameColor, 0.8);
                flame.graphics.moveTo(flameX, flameY);
                flame.graphics.lineTo(flameX - 4, flameY + flameHeight);
                flame.graphics.lineTo(flameX + 4, flameY + flameHeight);
                flame.graphics.lineTo(flameX, flameY);
                flame.graphics.endFill();
            }
        }
        
        private function flashStreak():void {
            _streakContainer.filters = [new GlowFilter(0xFFAA00, 1, 20, 20, 2)];
            
            // Remove flash after delay
            var timer:Timer = new Timer(300, 1);
            timer.addEventListener(TimerEvent.TIMER_COMPLETE, function(e:TimerEvent):void {
                _streakContainer.filters = [];
            });
            timer.start();
        }
        
        // ============ HELPER ============
        
        private function createTextField(text:String, size:int, color:uint, bold:Boolean = false):TextField {
            var tf:TextField = new TextField();
            var format:TextFormat = new TextFormat();
            format.font = "Arial";
            format.size = size;
            format.color = color;
            format.bold = bold;
            format.align = TextFormatAlign.LEFT;
            
            tf.defaultTextFormat = format;
            tf.text = text;
            tf.selectable = false;
            tf.mouseEnabled = false;
            tf.autoSize = "left";
            
            return tf;
        }
        
        // ============ GETTERS ============
        
        public function get score():int { return _targetScore; }
        public function get streak():int { return _currentStreak; }
    }
}
