package castle {
    
    import flash.display.Sprite;
    import flash.display.Shape;
    import flash.text.TextField;
    import flash.text.TextFormat;
    import flash.text.TextFormatAlign;
    import flash.events.Event;
    
    /**
     * CastlePanel - UI panel showing castle stats and progress.
     * Displays score, level, streak, and milestone progress.
     */
    public class CastlePanel extends Sprite {
        
        // Visual elements
        private var _background:Shape;
        private var _scoreLabel:TextField;
        private var _scoreValue:TextField;
        private var _levelLabel:TextField;
        private var _levelValue:TextField;
        private var _streakLabel:TextField;
        private var _streakValue:TextField;
        private var _progressBar:Sprite;
        private var _progressFill:Shape;
        private var _progressLabel:TextField;
        private var _milestoneLabel:TextField;
        
        // Dimensions
        private var _panelWidth:Number;
        private var _panelHeight:Number;
        
        // Text formats
        private var _labelFormat:TextFormat;
        private var _valueFormat:TextFormat;
        private var _smallFormat:TextFormat;
        
        // Current values for animation
        private var _displayScore:int = 0;
        private var _targetScore:int = 0;
        
        /**
         * Constructor
         */
        public function CastlePanel(panelWidth:Number = 200, panelHeight:Number = 150) {
            _panelWidth = panelWidth;
            _panelHeight = panelHeight;
            
            createTextFormats();
            createBackground();
            createLabels();
            createProgressBar();
            
            // Initial update
            updateDisplay(0, 1, 0, "Build Your Castle!");
        }
        
        /**
         * Create text formats
         */
        private function createTextFormats():void {
            _labelFormat = new TextFormat();
            _labelFormat.font = "Arial";
            _labelFormat.size = 12;
            _labelFormat.color = 0xAAAAAA;
            _labelFormat.bold = false;
            
            _valueFormat = new TextFormat();
            _valueFormat.font = "Arial";
            _valueFormat.size = 18;
            _valueFormat.color = 0xFFFFFF;
            _valueFormat.bold = true;
            
            _smallFormat = new TextFormat();
            _smallFormat.font = "Arial";
            _smallFormat.size = 10;
            _smallFormat.color = 0xCCCCCC;
            _smallFormat.align = TextFormatAlign.CENTER;
        }
        
        /**
         * Create panel background
         */
        private function createBackground():void {
            _background = new Shape();
            var g:* = _background.graphics;
            
            // Rounded panel background
            g.beginFill(0x1A1A2E, 0.9);
            g.lineStyle(2, 0x3A3A5E);
            g.drawRoundRect(0, 0, _panelWidth, _panelHeight, 15, 15);
            g.endFill();
            
            // Header accent
            g.beginFill(0x4A4A7E, 0.5);
            g.drawRoundRect(0, 0, _panelWidth, 30, 15, 15);
            g.drawRect(0, 15, _panelWidth, 15);
            g.endFill();
            
            addChild(_background);
        }
        
        /**
         * Create stat labels
         */
        private function createLabels():void {
            var yOffset:Number = 8;
            
            // Title
            var title:TextField = createTextField("CASTLE STATS", _labelFormat);
            title.x = (_panelWidth - title.textWidth) / 2;
            title.y = yOffset;
            addChild(title);
            
            yOffset = 40;
            
            // Score
            _scoreLabel = createTextField("Score", _labelFormat);
            _scoreLabel.x = 15;
            _scoreLabel.y = yOffset;
            addChild(_scoreLabel);
            
            _scoreValue = createTextField("0", _valueFormat);
            _scoreValue.x = _panelWidth - 80;
            _scoreValue.y = yOffset - 3;
            _scoreValue.width = 65;
            addChild(_scoreValue);
            
            yOffset += 28;
            
            // Level
            _levelLabel = createTextField("Level", _labelFormat);
            _levelLabel.x = 15;
            _levelLabel.y = yOffset;
            addChild(_levelLabel);
            
            _levelValue = createTextField("1", _valueFormat);
            _levelValue.x = _panelWidth - 80;
            _levelValue.y = yOffset - 3;
            _levelValue.width = 65;
            addChild(_levelValue);
            
            yOffset += 28;
            
            // Streak
            _streakLabel = createTextField("Streak", _labelFormat);
            _streakLabel.x = 15;
            _streakLabel.y = yOffset;
            addChild(_streakLabel);
            
            _streakValue = createTextField("0", _valueFormat);
            _streakValue.x = _panelWidth - 80;
            _streakValue.y = yOffset - 3;
            _streakValue.width = 65;
            addChild(_streakValue);
        }
        
        /**
         * Create milestone progress bar
         */
        private function createProgressBar():void {
            var yOffset:Number = 125;
            
            // Progress bar container
            _progressBar = new Sprite();
            _progressBar.x = 15;
            _progressBar.y = yOffset;
            
            // Background
            var bg:Shape = new Shape();
            bg.graphics.beginFill(0x2A2A4E);
            bg.graphics.drawRoundRect(0, 0, _panelWidth - 30, 12, 6, 6);
            bg.graphics.endFill();
            _progressBar.addChild(bg);
            
            // Fill
            _progressFill = new Shape();
            _progressBar.addChild(_progressFill);
            
            addChild(_progressBar);
            
            // Progress label
            _progressLabel = createTextField("0%", _smallFormat);
            _progressLabel.width = _panelWidth - 30;
            _progressLabel.x = 15;
            _progressLabel.y = yOffset - 2;
            addChild(_progressLabel);
            
            // Milestone label below bar
            _milestoneLabel = createTextField("", _smallFormat);
            _milestoneLabel.width = _panelWidth - 30;
            _milestoneLabel.x = 15;
            _milestoneLabel.y = yOffset + 14;
            addChild(_milestoneLabel);
        }
        
        /**
         * Helper: Create text field
         */
        private function createTextField(text:String, format:TextFormat):TextField {
            var tf:TextField = new TextField();
            tf.defaultTextFormat = format;
            tf.text = text;
            tf.selectable = false;
            tf.multiline = false;
            tf.wordWrap = false;
            tf.width = tf.textWidth + 10;
            tf.height = tf.textHeight + 5;
            return tf;
        }
        
        /**
         * Update display with new values
         */
        public function updateDisplay(score:int, level:int, streak:int, milestone:String):void {
            _targetScore = score;
            
            // Animate score change
            if (_displayScore != _targetScore) {
                addEventListener(Event.ENTER_FRAME, animateScore);
            }
            
            // Update level
            _levelValue.text = String(level);
            _levelValue.setTextFormat(_valueFormat);
            
            // Update streak with color
            _streakValue.text = String(streak);
            var streakFormat:TextFormat = new TextFormat();
            streakFormat.font = "Arial";
            streakFormat.size = 18;
            streakFormat.bold = true;
            
            if (streak >= 10) {
                streakFormat.color = 0xFFD700; // Gold
            } else if (streak >= 5) {
                streakFormat.color = 0x00FF00; // Green
            } else if (streak >= 3) {
                streakFormat.color = 0x00BFFF; // Light blue
            } else {
                streakFormat.color = 0xFFFFFF; // White
            }
            _streakValue.setTextFormat(streakFormat);
            
            // Update milestone label
            _milestoneLabel.text = milestone;
            _milestoneLabel.setTextFormat(_smallFormat);
            
            // Update progress bar
            updateProgressBar(score);
        }
        
        /**
         * Animate score counting up
         */
        private function animateScore(e:Event):void {
            var diff:int = _targetScore - _displayScore;
            var step:int = Math.ceil(Math.abs(diff) / 10);
            
            if (diff > 0) {
                _displayScore = Math.min(_displayScore + step, _targetScore);
            } else if (diff < 0) {
                _displayScore = Math.max(_displayScore - step, _targetScore);
            }
            
            _scoreValue.text = String(_displayScore);
            _scoreValue.setTextFormat(_valueFormat);
            
            if (_displayScore == _targetScore) {
                removeEventListener(Event.ENTER_FRAME, animateScore);
            }
        }
        
        /**
         * Update progress bar based on score
         */
        private function updateProgressBar(score:int):void {
            // Find current and next milestone
            var currentMilestone:int = 0;
            var nextMilestone:int = 100;
            
            for (var i:int = 0; i < CastleConfig.SCORE_MILESTONES.length; i++) {
                if (score >= CastleConfig.SCORE_MILESTONES[i]) {
                    currentMilestone = CastleConfig.SCORE_MILESTONES[i];
                    if (i + 1 < CastleConfig.SCORE_MILESTONES.length) {
                        nextMilestone = CastleConfig.SCORE_MILESTONES[i + 1];
                    } else {
                        nextMilestone = currentMilestone + 100;
                    }
                }
            }
            
            // Calculate progress
            var progress:Number = (score - currentMilestone) / (nextMilestone - currentMilestone);
            progress = Math.max(0, Math.min(1, progress));
            
            // Draw fill
            var barWidth:Number = _panelWidth - 30;
            var fillWidth:Number = barWidth * progress;
            
            _progressFill.graphics.clear();
            if (fillWidth > 0) {
                // Gradient fill
                _progressFill.graphics.beginFill(getProgressColor(progress));
                _progressFill.graphics.drawRoundRect(0, 0, fillWidth, 12, 6, 6);
                _progressFill.graphics.endFill();
                
                // Shine effect
                _progressFill.graphics.beginFill(0xFFFFFF, 0.2);
                _progressFill.graphics.drawRoundRect(0, 0, fillWidth, 4, 3, 3);
                _progressFill.graphics.endFill();
            }
            
            // Update percentage label
            var pct:int = Math.floor(progress * 100);
            _progressLabel.text = pct + "% to next milestone (" + nextMilestone + ")";
            _progressLabel.setTextFormat(_smallFormat);
        }
        
        /**
         * Get progress bar color based on fill amount
         */
        private function getProgressColor(progress:Number):uint {
            if (progress >= 0.8) return 0x00FF00; // Green
            if (progress >= 0.5) return 0xFFFF00; // Yellow
            if (progress >= 0.3) return 0xFFA500; // Orange
            return 0x4A90D9; // Blue
        }
        
        /**
         * Show milestone reached animation
         */
        public function showMilestoneReached(milestoneName:String):void {
            // Flash the panel
            var flash:Shape = new Shape();
            flash.graphics.beginFill(0xFFD700, 0.5);
            flash.graphics.drawRoundRect(0, 0, _panelWidth, _panelHeight, 15, 15);
            flash.graphics.endFill();
            addChild(flash);
            
            // Fade out flash
            var fadeStep:Number = 0.05;
            addEventListener(Event.ENTER_FRAME, function(e:Event):void {
                flash.alpha -= fadeStep;
                if (flash.alpha <= 0) {
                    removeEventListener(Event.ENTER_FRAME, arguments.callee);
                    if (flash.parent) {
                        removeChild(flash);
                    }
                }
            });
            
            // Update milestone label with celebration
            _milestoneLabel.text = "★ " + milestoneName + " UNLOCKED! ★";
            var celebFormat:TextFormat = new TextFormat();
            celebFormat.font = "Arial";
            celebFormat.size = 10;
            celebFormat.color = 0xFFD700;
            celebFormat.bold = true;
            celebFormat.align = TextFormatAlign.CENTER;
            _milestoneLabel.setTextFormat(celebFormat);
        }
        
        /**
         * Update from CastleState
         */
        public function updateFromState(state:CastleState, currentStreak:int = 0):void {
            var milestoneObj:Object = CastleConfig.getMilestoneForScore(state.totalScore);
            var milestoneName:String = milestoneObj.name;
            updateDisplay(state.totalScore, state.level, currentStreak, milestoneName);
            
            // Check for new milestone
            if (state.currentMilestone != milestoneName && milestoneName != "Empty Land") {
                showMilestoneReached(milestoneName);
            }
        }
        
        /**
         * Set streak value separately (for real-time updates)
         */
        public function setStreak(streak:int):void {
            _streakValue.text = String(streak);
            
            var streakFormat:TextFormat = new TextFormat();
            streakFormat.font = "Arial";
            streakFormat.size = 18;
            streakFormat.bold = true;
            
            if (streak >= 10) {
                streakFormat.color = 0xFFD700;
            } else if (streak >= 5) {
                streakFormat.color = 0x00FF00;
            } else if (streak >= 3) {
                streakFormat.color = 0x00BFFF;
            } else {
                streakFormat.color = 0xFFFFFF;
            }
            _streakValue.setTextFormat(streakFormat);
        }
    }
}
