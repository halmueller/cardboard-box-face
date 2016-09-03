//
// Inspiration projects:
// https://github.com/haven04/SceneKitVRSample
// https://github.com/NathanFlurry/SceneKitVR
// https://github.com/stevenjs/VR-iOS-Experiment

//  GameViewController.swift
//  CardboardBoxFace
//
//  Created by Eric Mentele on 5/11/16.
//  Copyright (c) 2016 Eric Mentele. All rights reserved.

import UIKit
import QuartzCore
import SceneKit
import CoreMotion

class GameViewController: UIViewController, SCNSceneRendererDelegate {
    @IBOutlet weak var leftEye: SCNView!
    @IBOutlet weak var rightEye: SCNView!

    var scene : SCNScene?
    // Create camera nodes
    var camerasNode : SCNNode?
    var cameraRollNode : SCNNode?
    var cameraPitchNode : SCNNode?
    var cameraYawNode : SCNNode?
    
    // create a room for the scene
    let roomWidth:Float = 200.0
    let roomHeight:Float = 200.0
    
    // Track head movement
    var motionManager : CMMotionManager?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        scene = SCNScene(named: "art.scnassets/ship.scn")!
        createFloor()

        // Add the scene to the views.
        leftEye?.scene = scene
        rightEye?.scene = scene
        rightEye.showsStatistics = true
        
        // Create view points in the scene
        let leftCamera = SCNCamera()
        let rightCamera = SCNCamera()
        // Watch out for this! xFar default is 100 and it will clip everything past that.
        leftCamera.automaticallyAdjustsZRange = true
        rightCamera.automaticallyAdjustsZRange = true
        
        let camX = 0.0 as Float
        let camY = 10.0 as Float
        let camZ = 0.0 as Float
        
        // Create nodes to act as a point in space for the cameras to view from.
        let leftCameraNode = SCNNode()
        leftCameraNode.camera = leftCamera
        leftCameraNode.position = SCNVector3(x: camX - 2.5, y: camY, z: camZ)
        
        let rightCameraNode = SCNNode()
        rightCameraNode.camera = rightCamera
        rightCameraNode.position = SCNVector3(x: camX + 2.5, y: camY, z: camZ)
        
        // Create a center point for the camera nodes to move together.
        camerasNode = SCNNode()
        camerasNode!.position = SCNVector3(x: camX, y:camY, z:camZ)
        camerasNode!.addChildNode(leftCameraNode)
        camerasNode!.addChildNode(rightCameraNode)
        
        // MAGIC that controls camera with head position.
        let camerasNodeAngles = getCamerasNodeAngle()
        camerasNode!.eulerAngles = SCNVector3Make(Float(camerasNodeAngles[0]), Float(camerasNodeAngles[1]), Float(camerasNodeAngles[2]))
        
        cameraRollNode = SCNNode()
        cameraRollNode!.addChildNode(camerasNode!)
        
        cameraPitchNode = SCNNode()
        cameraPitchNode!.addChildNode(cameraRollNode!)
        
        cameraYawNode = SCNNode()
        cameraYawNode!.addChildNode(cameraPitchNode!)
        
        scene!.rootNode.addChildNode(cameraYawNode!)
        
        // Once camera nodes are set up then make them the points of view for the eye views.
        leftEye?.pointOfView = leftCameraNode
        rightEye?.pointOfView = rightCameraNode
        
        // Respond to user head movement. Refreshes the position of the camera 60 times per second.
        motionManager = CMMotionManager()
        motionManager?.deviceMotionUpdateInterval = 1.0 / 60.0
        motionManager?.startDeviceMotionUpdates(using: CMAttitudeReferenceFrame.xArbitraryZVertical)
        
        // Make sure the views render the scene.
        leftEye.delegate = self
        rightEye.delegate = self
        
        leftEye.isPlaying = true
        rightEye.isPlaying = true
    }
    
    func getCamerasNodeAngle() -> [Double] {
        var camerasNodeAngle1: Double! = 0.0
        var camerasNodeAngle2: Double! = 0.0
        let orientation = UIApplication.shared.statusBarOrientation.rawValue
        if orientation == 1 {
            camerasNodeAngle1 = -M_PI_2
        } else if orientation == 2 {
            camerasNodeAngle1 = M_PI_2
        } else if orientation == 3 {
            camerasNodeAngle1 = 0.0
            camerasNodeAngle2 = M_PI
        }
        
        return [ -M_PI_2, camerasNodeAngle1, camerasNodeAngle2 ]
    }
    
    func renderer(_ aRenderer: SCNSceneRenderer, updateAtTime time: TimeInterval)
    {
        // Render the scene
        DispatchQueue.main.async { () -> Void in
            if let mm = self.motionManager, let motion = mm.deviceMotion {
                let currentAttitude = motion.attitude
                
                var roll : Double = currentAttitude.roll
                if(UIApplication.shared.statusBarOrientation == UIInterfaceOrientation.landscapeRight){ roll = -1.0 * (-M_PI - roll)}
                
                self.cameraRollNode!.eulerAngles.x = Float(roll)
                self.cameraPitchNode!.eulerAngles.z = Float(currentAttitude.pitch)
                self.cameraYawNode!.eulerAngles.y = Float(currentAttitude.yaw)
            }
        }
    }
    
    func createFloor() {
        // create floor for room
        let floor = SCNFloor()
        floor.reflectivity = 0
        floor.firstMaterial?.diffuse.contents = "art.scnassets/wood.png"
        floor.firstMaterial?.diffuse.contentsTransform = SCNMatrix4MakeScale(200.0, 200.0, 200.0)
        floor.firstMaterial?.locksAmbientWithDiffuse = true
        floor.firstMaterial?.diffuse.wrapS = SCNWrapMode.repeat;
        floor.firstMaterial?.diffuse.wrapT = SCNWrapMode.repeat;
        floor.firstMaterial?.diffuse.mipFilter = SCNFilterMode.nearest;
        floor.firstMaterial?.isDoubleSided = false
        let floorNode = SCNNode(geometry: floor)
        floorNode.physicsBody = SCNPhysicsBody.static()
        scene!.rootNode.addChildNode(floorNode)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

}
