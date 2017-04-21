//
//  IR_GameListViewController.swift
//  iRulo
//
//  Created by cice on 7/4/17.
//  Copyright © 2017 cice. All rights reserved.
//

import UIKit
import CoreData

class IR_GameListViewController: UIViewController {

    //MARKS: - Variables GLOBALES
    var managedContext : NSManagedObjectContext?
    var listGames = [Game]()
    
    //MARK: - IBOutlets
    @IBOutlet weak var myFilterSegmentControll: UISegmentedControl!
    @IBOutlet weak var myCollectionView: UICollectionView!
    
    //MARK: - IBActions
    @IBAction func filterChangeACTION(_ sender: Any) {
        
        performGamesQuery()
        
    }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        myCollectionView.delegate = self
        myCollectionView.dataSource = self
        myCollectionView.alwaysBounceVertical = true
        
        
        
        // Do any additional setup after loading the view.
        
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        performGamesQuery()
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    //MARK: - UTILS
    func formaColors(_ myString: String, myColor: UIColor) -> NSMutableAttributedString{
        
        let length = myString.characters.count
        
        let colonPosition = myString.indexOf(":")!
        
        let myMutableString = NSMutableAttributedString(string: myString)
        
        myMutableString.addAttribute(NSForegroundColorAttributeName, value: myColor, range: NSRange(location: 0, length: length))
        myMutableString.addAttribute(NSForegroundColorAttributeName, value: UIColor.black, range: NSRange(location: 0, length: colonPosition + 1))
        
        return myMutableString
    }
    
    //MARK: - Consulta de COREDATA
    func performGamesQuery(){
        
        //1-> request
        let customRequest : NSFetchRequest<Game> = Game.fetchRequest()
        
        //2-> auditoria
        let sortByDate = NSSortDescriptor(key: "dateCreated", ascending: false)
        customRequest.sortDescriptors = [sortByDate]
        
        if myFilterSegmentControll.selectedSegmentIndex == 0{
            let customPredicate = NSPredicate(format: "borrowed = true")
            customRequest.predicate = customPredicate
        }
        
        do{
            let fetchGames = try managedContext?.fetch(customRequest)
            if let fetchGamesDes = fetchGames{
                listGames = fetchGamesDes
                self.myCollectionView.reloadData()
            }
            
            
        }catch let error{
            print("Error: \(error.localizedDescription)")
        }
        
    }
    
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "addGameSegue" {
            let navVC = segue.destination as! UINavigationController
            let detalleVC = navVC.topViewController as! IR_AddGameViewController
            detalleVC.managedContext = managedContext
            detalleVC.irDelagate = self
        }
        
        if segue.identifier == "editGameSegue" {
            let detalleVC = segue.destination as! IR_AddGameViewController
            detalleVC.managedContext = managedContext
            
            let selectIndex = myCollectionView.indexPathsForSelectedItems?.first?.row
            let gameInd = listGames[selectIndex!]
            
            detalleVC.game = gameInd
            detalleVC.irDelagate = self
            
        }
    }
 

}


//TODO: - FIN DE LA CLASE
extension IR_GameListViewController : UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: self.view.frame.width - 16, height: 400.0)
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        if listGames.count == 0 {
            let imageBackground = UIImageView(image: #imageLiteral(resourceName: "img_empty_list"))
            imageBackground.contentMode = .scaleAspectFit
            myCollectionView.backgroundView = imageBackground
        } else {
            myCollectionView.backgroundView = UIView()
        }
        
        return listGames.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let customCell = myCollectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! IR_DetailCustomCell
        
        let gameModel = listGames[indexPath.row]
        
        
        
        //definimos colores
        var miColorPrestado = CONSTANTES.COLORES.COLOR_ROJO
        
        if !gameModel.borrowed {
            miColorPrestado = CONSTANTES.COLORES.COLOR_AZUL
        }
        
        //alimentamos la celda
        customCell.myNameGame.text = gameModel.title
        customCell.myBorrowedLB.attributedText = formaColors("PRESTADO: \(gameModel.borrowed ? "SI" : "NO")", myColor: miColorPrestado)
        
        if let borrowedTo = gameModel.borrowedTo {
            customCell.myBorrowedToLB.attributedText = formaColors("A: \(borrowedTo)", myColor: miColorPrestado)
        } else {
            customCell.myBorrowedToLB.attributedText = formaColors("A: -- ", myColor: miColorPrestado)
        }
        
        if let borrowedDate = gameModel.borrowedDate as Date? {
            let myDateFormatter = DateFormatter()
            myDateFormatter.dateFormat = "dd/MM/yyyy"
            myDateFormatter.string(from: borrowedDate)
            
            customCell.myBorreowedDateLB.attributedText = formaColors("FECHA: \(myDateFormatter.string(from: borrowedDate))", myColor: miColorPrestado)
        } else {
            
            customCell.myBorreowedDateLB.attributedText = formaColors("FECHA: -- ", myColor: miColorPrestado)
            
        }
        
        if let imageGame = gameModel.image as Data? {
            
            customCell.myImagenView.image = UIImage(data: imageGame)
            
        }
        
        //ajustar la celda graficamente
        customCell.layer.masksToBounds = false
        customCell.layer.shadowOffset = CGSize(width: 1.0, height: 1.0)
        customCell.layer.shadowColor = CONSTANTES.COLORES.BLANCO_TEXTO_BARRA_NAVEGACION.cgColor
        customCell.layer.shadowRadius = 2.0
        customCell.layer.shadowOpacity = 0.2
        
        
        return customCell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        performSegue(withIdentifier: "editGameSegue", sender: self)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offSetY = scrollView.contentOffset.y
        if offSetY < -120 {
            performSegue(withIdentifier: "addGameSegue", sender: self)
        }
    }
   
}

extension IR_GameListViewController : IR_AddGameViewControllerDelegate {
    
    func didAddGame() {
        myCollectionView.reloadData()
    }
    
}

extension String {
    
    func indexOf(_ myString : String) -> Int?{
        
        if let myRango = self.range(of: myString) {
            return distance(from: self.startIndex, to: myRango.lowerBound)
        } else {
            return nil
        }
        
    }
    
}







