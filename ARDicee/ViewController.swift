//
//  ViewController.swift
//  ARDicee
//
//  Created by Klemen Tušar on 21.07.2018.
//  Copyright © 2018 Klemen Tušar. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {

    var diceArray = [SCNNode]()
    
    @IBOutlet var sceneView: ARSCNView!
    
    // MARK: - Life cycle methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // display yellow feature points on the screen while it's trying to detect a plane
        // self.sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // add some lighting
        sceneView.autoenablesDefaultLighting = true
    
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration() // iPhone 6s and newer models only!
        
        configuration.planeDetection = .horizontal // only world tracking supports this

        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    // MARK: - Dice rendering methods
    
    // detect touches on the screen and interpret it as locations in the real world
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // gets called when a touch is detected in the view or in the window
        // get the touches from the user and use ARKit to convert it/them to locations
        if let touch = touches.first {
            let touchLocation = touch.location(in: sceneView)
            
            // convert the 2D location into a 3D location
            let results = sceneView.hitTest(touchLocation, types: .existingPlaneUsingExtent)
            
            // if there was a touch detected
            if let hitResult = results.first {
                 addDice(atLocation: hitResult)
            }
        }
    }
    
    func addDice(atLocation location: ARHitTestResult) {
        // Create a dice new scene
        let diceScene = SCNScene(named: "art.scnassets/diceCollada.scn")!
        if let diceNode = diceScene.rootNode.childNode(withName: "Dice", recursively: true) {
            diceNode.position = SCNVector3(x: location.worldTransform.columns.3.x,
                                           // to prevent our dice from being half sunken into the plane to the Y axis the radius of the diceNode's boundingSphere
                                           y: location.worldTransform.columns.3.y + diceNode.boundingSphere.radius,
                                           z: location.worldTransform.columns.3.z)
            diceArray.append(diceNode)
            
            sceneView.scene.rootNode.addChildNode(diceNode)
            
            roll(dice: diceNode)
        }
    }
    
    func roll(dice: SCNNode) {
        // we only need to rotate the X and Z axis and not the Y axis, because that would not change the face of the die
        let ranomdX = Float(arc4random_uniform(4) + 1) * (Float.pi/2)
        let ranomdZ = Float(arc4random_uniform(4) + 1) * (Float.pi/2)
        
        dice.runAction(SCNAction.rotateBy(x: CGFloat(ranomdX * 5),
                                          y: 0,
                                          z: CGFloat(ranomdZ * 5),
                                          duration: 0.5))
    }
    
    func rollAll() {
        if !diceArray.isEmpty {
            for dice in diceArray {
                roll(dice: dice)
            }
        }
    }
    
    @IBAction func rollAgain(_ sender: UIBarButtonItem) {
        rollAll()
    }
    
    // shake gesture
    override func motionEnded(_ motion: UIEventSubtype, with event: UIEvent?) {
        print("device was shaken")
        rollAll()
    }
    
    @IBAction func removeAllDice(_ sender: UIBarButtonItem) {
        if !diceArray.isEmpty {
            for dice in diceArray {
                dice.removeFromParentNode()
            }
        }
    }
    
    // MARK: - ARSCNViewDelegateMethods
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        // detect horizontal planes in the real world
        // gets called once a plane is detected
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        
        let planeNode = createPlane(withPlaneAnchor: planeAnchor)
        
        node.addChildNode(planeNode)
    }
    
    // MARK: - Plane rendering methods
    
    func createPlane(withPlaneAnchor planeAnchor: ARPlaneAnchor) -> SCNNode {
        // an SCNPlane is by default a vertical plane
        // check the docs https://developer.apple.com/documentation/scenekit/scnplane
        let plane = SCNPlane(width: CGFloat(planeAnchor.extent.x), height: CGFloat(planeAnchor.extent.z))
        
        let planeNode = SCNNode()
        planeNode.position = SCNVector3(x: planeAnchor.center.x, y: 0, z: planeAnchor.center.z)
        
        // because the above SCNPlane is by default vertical we have to rotate it so that it becomes horizontal
        planeNode.transform = SCNMatrix4MakeRotation(-Float.pi/2, 1, 0, 0) // the rotation angle is in counter clokwise radians
        
        let gridMaterial = SCNMaterial()
        gridMaterial.diffuse.contents = UIImage(named: "art.scnassets/grid.png")
        
        plane.materials = [gridMaterial]
        planeNode.geometry = plane
        
        return planeNode
    }
}
