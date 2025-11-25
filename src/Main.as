package {
    import flash.display.Sprite;
    import flash.text.TextField;
    import flash.text.TextFormat;
    import flash.system.Capabilities;
    import flash.display.StageAlign;
    import flash.display.StageScaleMode;
    import flash.events.Event;

    public class Main extends Sprite {
        private var _hud:HUD;
        private var _gameController:GameController;

        public function Main() {
            // Setup stage
            stage.scaleMode = StageScaleMode.NO_SCALE;
            stage.align = StageAlign.TOP_LEFT;
            stage.addEventListener(Event.RESIZE, onResize);

            // Initialize HUD
            _hud = new HUD();
            addChild(_hud);

            // Initialize Game Controller
            _gameController = GameController.getInstance();
            _gameController.initialize(_hud);

            // Remove old debug text (will be replaced by HUD)
            // Keep platform info for debugging if needed
            trace("Cognitive Castle initialized on: " + Capabilities.version);
            trace("Resolution: " + stage.stageWidth + "x" + stage.stageHeight);
        }

        private function onResize(event:Event):void {
            if (_hud) {
                _hud.onResize();
            }
        }
    }
}