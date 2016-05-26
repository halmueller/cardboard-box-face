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
// TODO: Set tap gesture to recenter view, pedometer to mover forward.

import UIKit
import QuartzCore
import SceneKit
import CoreMotion

class GameViewController: UIViewController, SCNSceneRendererDelegate {
    @IBOutlet weak var leftEye: SCNView!
    @IBOutlet weak var rightEye: SCNView!

    //plane for scene
    var scene : SCNScene?
    var camerasNode : SCNNode?
    var cameraRollNode : SCNNode?
    var cameraPitchNode : SCNNode?
    var cameraYawNode : SCNNode?
    
    // create a room for the scene
    let roomWidth:Float = 200.0
    let roomHeight:Float = 200.0
    
    var motionManager : CMMotionManager?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        scene = SCNScene(named: "art.scnassets/ship.scn")!
        createRoom()

        leftEye?.scene = scene
        rightEye?.scene = scene
        
        // Create cameras
        let camX = 0.0 as Float
        let camY = 60.0 as Float
        let camZ = 0.0 as Float
        // Watch out for this! xFar default is 100 and it will clip everything past that.
        let zFar = 500.0
        
        
        let leftCamera = SCNCamera()
        let rightCamera = SCNCamera()
        leftCamera.zFar = zFar
        rightCamera.zFar = zFar
        
       
        
        let leftCameraNode = SCNNode()
        leftCameraNode.camera = leftCamera
        leftCameraNode.position = SCNVector3(x: camX - 2.5, y: camY, z: camZ)
        
        let rightCameraNode = SCNNode()
        rightCameraNode.camera = rightCamera
        rightCameraNode.position = SCNVector3(x: camX + 5.0, y: camY, z: camZ)
        
        camerasNode = SCNNode()
        camerasNode!.position = SCNVector3(x: camX, y:camY, z:camZ)
        camerasNode!.addChildNode(leftCameraNode)
        camerasNode!.addChildNode(rightCameraNode)
        
        let camerasNodeAngles = getCamerasNodeAngle()
        camerasNode!.eulerAngles = SCNVector3Make(Float(camerasNodeAngles[0]), Float(camerasNodeAngles[1]), Float(camerasNodeAngles[2]))
        
        cameraRollNode = SCNNode()
        cameraRollNode!.addChildNode(camerasNode!)
        
        cameraPitchNode = SCNNode()
        cameraPitchNode!.addChildNode(cameraRollNode!)
        
        cameraYawNode = SCNNode()
        cameraYawNode!.addChildNode(cameraPitchNode!)
        
        scene!.rootNode.addChildNode(cameraYawNode!)
        
        leftEye?.pointOfView = leftCameraNode
        rightEye?.pointOfView = rightCameraNode
        
        // Respond to user head movement. Refreshes the position of the camera 120 times per second.
        motionManager = CMMotionManager()
        motionManager?.deviceMotionUpdateInterval = 1.0 / 120.0
        motionManager?.startDeviceMotionUpdatesUsingReferenceFrame(CMAttitudeReferenceFrame.XArbitraryZVertical)
        
        leftEye?.delegate = self
        
        leftEye?.playing = true
        rightEye?.playing = true
    }
    
    func getCamerasNodeAngle() -> [Double] {
        var camerasNodeAngle1: Double! = 0.0
        var camerasNodeAngle2: Double! = 0.0
        let orientation = UIApplication.sharedApplication().statusBarOrientation.rawValue
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
    
    func handleTap(gestureRecognize: UIGestureRecognizer) {
        camerasNode!.eulerAngles = SCNVector3Make(degreesToRadians(0.0), 0, 0)
    }
    
    func renderer(aRenderer: SCNSceneRenderer, updateAtTime time: NSTimeInterval)
    {
        // Render the scene
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            if let mm = self.motionManager, let motion = mm.deviceMotion {
                let currentAttitude = motion.attitude
                
                var roll : Double = currentAttitude.roll
                if(UIApplication.sharedApplication().statusBarOrientation == UIInterfaceOrientation.LandscapeRight){ roll = -1.0 * (-M_PI - roll)}
                
                self.cameraRollNode!.eulerAngles.x = Float(roll)
                self.cameraPitchNode!.eulerAngles.z = Float(currentAttitude.pitch)
                self.cameraYawNode!.eulerAngles.y = Float(currentAttitude.yaw)
            }
        }
    }
    
    func createRoom() {
        // create floor for room
        let floor = SCNFloor()
        floor.reflectivity = 0
        floor.firstMaterial?.diffuse.contents = "art.scnassets/wood.png"
        floor.firstMaterial?.diffuse.contentsTransform = SCNMatrix4MakeScale(200.0, 200.0, 200.0)
        floor.firstMaterial?.locksAmbientWithDiffuse = true
        floor.firstMaterial?.diffuse.wrapS = SCNWrapMode.Repeat;
        floor.firstMaterial?.diffuse.wrapT = SCNWrapMode.Repeat;
        floor.firstMaterial?.diffuse.mipFilter = SCNFilterMode.Nearest;
        floor.firstMaterial?.doubleSided = false
        let floorNode = SCNNode(geometry: floor)
        floorNode.physicsBody = SCNPhysicsBody.staticBody()
        scene!.rootNode.addChildNode(floorNode)
        
        // create walls for room
        let halfWidth:Float = roomWidth / 2
        let halfHeight:Float = roomHeight / 2
        
        let wallTextureImage:UIImage = UIImage(named: "art.scnassets/wall.jpg")!
        let wallTextureHeightScale:Float = roomHeight / Float(wallTextureImage.size.height)
        let wallTextureWidthScale:Float = roomWidth / Float(wallTextureImage.size.width) / wallTextureHeightScale
        
        let wall = SCNPlane(width: CGFloat(roomWidth), height: CGFloat(roomHeight))
        
        wall.firstMaterial?.diffuse.contents = wallTextureImage
        wall.firstMaterial?.diffuse.contentsTransform = SCNMatrix4MakeScale(wallTextureWidthScale, 1, 1)
        wall.firstMaterial?.diffuse.wrapS = SCNWrapMode.Repeat
        wall.firstMaterial?.diffuse.wrapT = SCNWrapMode.Mirror
        wall.firstMaterial?.diffuse.mipFilter = SCNFilterMode.Nearest;
        wall.firstMaterial?.locksAmbientWithDiffuse = true
        wall.firstMaterial?.doubleSided = false
        wall.firstMaterial?.shininess = 0.0
        
        var wallNode = SCNNode(geometry: wall)
        wallNode.position = SCNVector3Make(0, halfHeight, -halfWidth)
        wallNode.physicsBody = SCNPhysicsBody.staticBody()
        wallNode.physicsBody?.restitution = 1.0
        wallNode.castsShadow = false
        
        scene!.rootNode.addChildNode(wallNode)
        
        wallNode = wallNode.clone()
        wallNode.position = SCNVector3Make(-halfWidth, halfHeight, 0)
        wallNode.rotation = SCNVector4Make(0, 1, 0, Float(M_PI_2))
        scene!.rootNode.addChildNode(wallNode)
        
        wallNode = wallNode.clone()
        wallNode.position = SCNVector3Make(halfWidth, halfHeight, 0)
        wallNode.rotation = SCNVector4Make(0, 1, 0, Float(-M_PI_2))
        scene!.rootNode.addChildNode(wallNode)
        
        wallNode = wallNode.clone()
        wallNode.position = SCNVector3Make(0, halfHeight, halfWidth)
        wallNode.rotation = SCNVector4Make(0, 1, 0, Float(M_PI))
        scene!.rootNode.addChildNode(wallNode)
    }
    
    func degreesToRadians(degrees: Float) -> Float {
        return (degrees * Float(M_PI)) / 180.0
    }
    
    func radiansToDegrees(radians: Float) -> Float {
        return (180.0/Float(M_PI)) * radians
    }
    
    override func shouldAutorotate() -> Bool {
        return false
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return .Landscape
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

}
