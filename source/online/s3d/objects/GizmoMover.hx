package online.s3d.objects;

import online.s3d.util.AudioUtil;
import away3d.audio.drivers.SimplePanVolumeDriver;
import motion.Actuate;
import openfl.media.Sound;
import openfl.media.SoundChannel;
import away3d.events.MouseEvent3D;
import away3d.containers.ObjectContainer3D;
import openfl.events.MouseEvent;
import openfl.geom.Vector3D;
import away3d.containers.View3D;
import openfl.net.URLRequest;
import away3d.audio.Sound3D;

abstract DragDirection(String) from String to String {
    public static inline var X:String = "x";
	public static inline var Y:String = "y";
	public static inline var Z:String = "z";
}

/**
    this class is partly limited, please register mouse out event somewhere in your code and call `direction = null;` on its dispatch
    also remember to call `update()` on enter frame event
**/
class GizmoMover extends ObjectContainer3D {
    public var xAxis:GizmoArrow;
    public var yAxis:GizmoArrow;
    public var zAxis:GizmoArrow;

    public var target(default, set):ObjectContainer3D;
    public var direction:DragDirection = null;
    public var dragRange:Float = 10000;

    public var grid:Vector3D = new Vector3D(1, 1, 1);

    var view:View3D;

    public function new(view:View3D) {
        super();

        this.view = view;

        // go forward my mouse children!
        mouseChildren = true;

        xAxis = new GizmoArrow(0xFF0000);
        yAxis = new GizmoArrow(0x00FF00);
        zAxis = new GizmoArrow(0x0000FF);

        xAxis.rotationZ = -90;
        yAxis.rotationY = 0;
        zAxis.rotationX = 90;

        xAxis.visible = false;
        yAxis.visible = false;
        zAxis.visible = false;

        addChild(xAxis);
        addChild(yAxis);
        addChild(zAxis);

        xAxis.addEventListener(MouseEvent3D.MOUSE_DOWN, onXAxisDrag);
        yAxis.addEventListener(MouseEvent3D.MOUSE_DOWN, onYAxisDrag);
        zAxis.addEventListener(MouseEvent3D.MOUSE_DOWN, onZAxisDrag);
	}

    function set_target(v:ObjectContainer3D) {
        target = v;
        xAxis.visible = v != null;
        yAxis.visible = v != null;
        zAxis.visible = v != null;
        return target;
    }

    function onAxisOut(?e:MouseEvent) {
        direction = null;
    }

    function onXAxisDrag(?e:MouseEvent3D) {
        direction = DragDirection.X;
        beginDrag();
    }
    
    function onYAxisDrag(?e:MouseEvent3D) {
        direction = DragDirection.Y;
        beginDrag();
    }

    function onZAxisDrag(?e:MouseEvent3D) {
        direction = DragDirection.Z;
        beginDrag();
    }

    function onMouseMove(?e:MouseEvent) {
        updateDrag();
    }

    public function update():Void {
        if (target != null) {
            x = target.x;
            y = target.y;
            z = target.z;

            updateArrowScale(xAxis);
            updateArrowScale(yAxis);
            updateArrowScale(zAxis);
        }

        xAxis.visible = target != null && (direction == null || direction == DragDirection.X);
        yAxis.visible = target != null && (direction == null || direction == DragDirection.Y);
        zAxis.visible = target != null && (direction == null || direction == DragDirection.Z);

        if (direction != null)
            updateDrag();
        else {
            if (_alienSound != null && !_alienSound.paused) {
                _alienSound.pause();
                if (_alienNOOO != null)
                    _alienNOOO.visible = false;
            }
        }
    }

    function updateArrowScale(arrow:GizmoArrow) {
        final finalScale = openfl.geom.Vector3D.distance(view.camera.scenePosition, arrow.scenePosition) * 0.0015;
        arrow.scaleX = finalScale;
        arrow.scaleY = finalScale;
        arrow.scaleZ = finalScale;
    }

    var _alienSound:Sound3D;
    var _alienNOOO:StaticSprite3D;

    var _startMouseX:Float;
    var _startMouseY:Float;
    var _totalMoved:Float;
    public function beginDrag() {
        _startMouseX = view.mouseX;
        _startMouseY = view.mouseY;
        _totalMoved = 0;

        if (target?.id == 'alien') {
            if (_alienSound == null) {
                _alienSound = new Sound3D(AudioUtil.loadMonoSound("assets/sounds/marcianito.ogg"), view.camera, null, 1, 500);
                addChild(_alienSound);
            }
            else {
                if (!_alienSound.paused)
                    _alienSound.pause();
            }

            if (_alienNOOO == null) {
                _alienNOOO = new StaticSprite3D({
                    image: "noo"
                });
                addChild(_alienNOOO);
            }
            
            _alienSound.play();
            _alienNOOO.visible = true;
            _alienLoop();
        }
    }

    function _alienLoop() {
        if (!_alienSound.playing) {
            _alienNOOO.visible = false;
            return;
        }

        _alienNOOO.visible = !_alienNOOO.visible;

        Actuate.timer(1 + Math.random() * 2).onComplete(_alienLoop);
    }

    // this is where the magic happens
    var _axisDirection:Vector3D = new Vector3D();
    function _updateDrag():Float {
        _axisDirection.setTo(0, 0, 0);
        if (direction == DragDirection.X) _axisDirection.x = 1;
        if (direction == DragDirection.Y) _axisDirection.y = 1;
        if (direction == DragDirection.Z) _axisDirection.z = 1;

        var projectStart:Vector3D = view.project(target.position);
        var projectEnd:Vector3D = view.project(target.position.add(_axisDirection));

        var screenAxisX:Float = projectEnd.x - projectStart.x;
        var screenAxisY:Float = projectEnd.y - projectStart.y;
        
        var mouseDeltaX:Float = view.mouseX - _startMouseX;
        var mouseDeltaY:Float = view.mouseY - _startMouseY;

        var axisLengthSq:Float = (screenAxisX * screenAxisX) + (screenAxisY * screenAxisY);
        
        if (axisLengthSq > 0) {
            var dotProduct:Float = (mouseDeltaX * screenAxisX) + (mouseDeltaY * screenAxisY);
            var t:Float = dotProduct / axisLengthSq;

            var potentialTotal:Float = _totalMoved + t;
            if (potentialTotal > dragRange) potentialTotal = dragRange;
            if (potentialTotal < -dragRange) potentialTotal = -dragRange;
            
            var allowedFrameT:Float = potentialTotal - _totalMoved;
            _totalMoved = potentialTotal;

            if (_axisDirection.x != 0) {
                var rawX:Float = target.position.x + (_axisDirection.x * allowedFrameT);
                var prevTargetX = target.x;
                target.x = Math.round(rawX / grid.x) * grid.x;
                return target.x - prevTargetX;
            }
            if (_axisDirection.y != 0) {
                var rawY:Float = target.position.y + (_axisDirection.y * allowedFrameT);
                var prevTargetY = target.y;
                target.y = Math.round(rawY / grid.y) * grid.y;
                return target.y - prevTargetY;
            }
            if (_axisDirection.z != 0) {
                var rawZ:Float = target.position.z + (_axisDirection.z * allowedFrameT);
                var prevTargetZ = target.z;
                target.z = Math.round(rawZ / grid.z) * grid.z;
                return target.z - prevTargetZ;
            }
        }

        return 0;
    }

    function updateDrag() {
        if (_updateDrag() != 0) {
            _startMouseX = view.mouseX;
            _startMouseY = view.mouseY;
        }
    }
}