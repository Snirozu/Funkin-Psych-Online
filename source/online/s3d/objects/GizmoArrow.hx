package online.s3d.objects;

import away3d.events.MouseEvent3D;
import openfl.display3D.Context3DCompareMode;
import away3d.containers.ObjectContainer3D;
import away3d.entities.Mesh;
import away3d.materials.ColorMaterial;
import away3d.primitives.ConeGeometry;
import away3d.primitives.CylinderGeometry;

class GizmoArrow extends ObjectContainer3D {
    public var stemMesh:Mesh;
    public var tipMesh:Mesh;
    
    public function new(color:UInt, stemLength:Float = 100, stemRadius:Float = 2, tipLength:Float = 20, tipRadius:Float = 6) {
        super();

        //apparently object container can't register mouse events for itself
        mouseChildren = true;
        
        var material:ColorMaterial = new ColorMaterial(color);
        material.bothSides = true;
        material.depthCompareMode = Context3DCompareMode.ALWAYS;

        var stemGeom:CylinderGeometry = new CylinderGeometry(stemRadius, stemRadius, stemLength, 16, 1, true, false);
        stemMesh = new Mesh(stemGeom, material);
        stemMesh.y = stemLength / 2;

        var tipGeom:ConeGeometry = new ConeGeometry(tipRadius, tipLength, 16, 1, true);
        tipMesh = new Mesh(tipGeom, material);
        tipMesh.y = stemLength + (tipLength / 2);

        stemMesh.mouseEnabled = true;
        tipMesh.mouseEnabled = true;

        addChild(stemMesh);
        addChild(tipMesh);

        stemMesh.addEventListener(MouseEvent3D.MOUSE_DOWN, onMouseDown);
        tipMesh.addEventListener(MouseEvent3D.MOUSE_DOWN, onMouseDown);
    }

    function onMouseDown(?e:MouseEvent3D) {
        dispatchEvent(e);
    }
}