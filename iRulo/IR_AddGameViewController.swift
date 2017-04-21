//
//  IR_AddGameViewController.swift
//  iRulo
//
//  Created by cice on 7/4/17.
//  Copyright © 2017 cice. All rights reserved.
//

import UIKit
import CoreData


protocol IR_AddGameViewControllerDelegate {
    func didAddGame()
}











class IR_AddGameViewController: UIViewController {

    
    //MARK: - Variables LOCALES
    var managedContext : NSManagedObjectContext?
    var game : Game?
    var datePicker : UIDatePicker!
    var dateFormatter = DateFormatter()
    
    var irDelagate : IR_AddGameViewControllerDelegate?
    
    //MARK: - IBOutlets
    @IBOutlet weak var myImagenGame: UIImageView!
    @IBOutlet weak var mySwitch: UISwitch!
    @IBOutlet weak var myTituloGame: UITextField!
    @IBOutlet weak var myBorrowedToGame: UITextField!
    @IBOutlet weak var myBorrowedDateGame: UITextField!
    @IBOutlet weak var myEliminarBTN: UIButton!
    
    //MARK: - IBActions
    @IBAction func eliminarGameFromCoreData(_ sender: Any) {
        
        if let context = managedContext {
            context.delete(game!)
            game = nil
            irDelagate?.didAddGame()
        }
        
    }
    
    @IBAction func prestadoGame(_ sender: UISwitch) {
        
        if sender.isOn {
            myBorrowedToGame.isEnabled = true
            myBorrowedDateGame.isEnabled = true
            myBorrowedDateGame.text = dateFormatter.string(from: Date())
        } else {
            myBorrowedToGame.isEnabled = false
            myBorrowedToGame.text = ""
            myBorrowedDateGame.isEnabled = false
            myBorrowedDateGame.text = ""
        }
    }
    
    //MARK: - LIFE VC
    override func viewDidLoad() {
        super.viewDidLoad()

        dateFormatter.dateFormat = "dd/MM/yyyy"
        
        //image
        myImagenGame.isUserInteractionEnabled = true
        let tapGR = UITapGestureRecognizer(target: self, action: #selector(pickerPhoto))
        myImagenGame.addGestureRecognizer(tapGR)
        
        //Teclado
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: Notification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: Notification.Name.UIKeyboardWillHide, object: nil)
        
        //datapicker
        datePicker = UIDatePicker(frame: CGRect(x: 0, y: 210, width: 320, height: 116))
        datePicker.datePickerMode = .date
        datePicker.addTarget(self, action: #selector(datePickerChange(_:)), for: .valueChanged)
        myBorrowedDateGame.inputView = datePicker
        
        //2 Logicas para el mismo viewController / añadir / editar
        if game == nil {
            
            self.title = "Añadir videojuego"
            self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelButtonPressed))
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(saveButtonPressed))
            
            myEliminarBTN.isHidden = true
            mySwitch.isOn = false
            
        } else {
            
            self.title = "Editar videojuego"
            myTituloGame.text = game?.title
            
            if let borrowed = game?.borrowed {
                mySwitch.isOn = borrowed
            }
            
            myBorrowedToGame.text = game?.borrowedTo
            
            if let borrowedDate = game?.borrowedDate as Date? {
                myBorrowedDateGame.text = dateFormatter.string(from: borrowedDate)
            }
            
            if let imageData = game?.image as Data? {
                myImagenGame.image = UIImage(data: imageData)
            }
            
            //myEliminarBTN.isHidden = false
            
            if !mySwitch.isOn {
                myBorrowedToGame.isEnabled = false
                myBorrowedDateGame.isEnabled = false
            }
            
        }
        
        func viewWillDisappear(_ animated: Bool){
            super.viewWillDisappear(animated)
            
            if game != nil {
                saveGame()
            }
        }

    }

    //MARK: - Utils
    func keyboardWillShow(_ notification : Notification){
        
        let info = notification.userInfo!
        let keyboardFrame = (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        let keyboardTime = (info[UIKeyboardAnimationDurationUserInfoKey] as! NSNumber).doubleValue
        
        UIView.animate(withDuration: keyboardTime) { 
            self.view.frame.origin.y = -(keyboardFrame.height)
        }
        
    }
    
    func keyboardWillHide(_ notification : Notification){
        let info = notification.userInfo!
        let keyboardTime = (info[UIKeyboardAnimationDurationUserInfoKey] as! NSNumber).doubleValue
        
        UIView.animate(withDuration: keyboardTime) {
            self.view.frame.origin.y = 0
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    func datePickerChange(_ picker : UIDatePicker) {
        myBorrowedDateGame.text = dateFormatter.string(from: datePicker.date)
    }
    
    func cancelButtonPressed() {
        self.dismiss(animated: true, completion: nil)
    }
    
    func saveButtonPressed() {
        //TODO: - Guardar el juego en CoreData
        saveGame()
        
        self.dismiss(animated: true, completion: nil)
    }
    
    func saveGame() {
        
        //Inyectamos el contexto
        if let context = managedContext {
            
            var editedGame : Game?
            
            if game == nil {
                editedGame = Game(context: context)
            } else {
                editedGame = game
            }
            
            if let editedGameDes = editedGame {
                
                editedGameDes.dateCreated = NSDate()
                editedGameDes.title = self.myTituloGame.text
                editedGameDes.borrowed = self.mySwitch.isOn
                
                if let imageData = myImagenGame.image {
                    editedGameDes.image = UIImageJPEGRepresentation(imageData, 0.5) as NSData?
                }
                
                if editedGameDes.borrowed {
                    editedGameDes.borrowedTo = self.myBorrowedToGame.text?.uppercased()
                    editedGameDes.borrowedDate = dateFormatter.date(from: myBorrowedDateGame.text!) as NSDate?
                } else {
                    editedGameDes.borrowedTo = nil
                    editedGameDes.borrowedDate = nil
                }
                
                do{
                    try context.save()
                    irDelagate?.didAddGame()
                }catch let error{
                    print("Error al intentar guardar los datos: \(error.localizedDescription)")
                }
                
            }
            
        }
        
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}//TODO: - FIN DE LA CLASE

extension IR_AddGameViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func pickerPhoto(){
        
        if UIImagePickerController.isSourceTypeAvailable(.camera){
            muestraMenu()
        } else {
            muestraLibreriaFotos()
        }
        
    }
    
    func muestraMenu(){
        let alertVC = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let cancelAction = UIAlertAction(title: "Cancelar", style: .cancel, handler: nil)
        let tomaFoto = UIAlertAction(title: "Toma foto", style: .default) { _ in
            
            self.muestraCamaraDispositivo()
            
        }
        let seleccionaFoto = UIAlertAction(title: "Selecciona desde Fotos", style: .default) { _ in
            
            self.muestraLibreriaFotos()
            
        }
        
        alertVC.addAction(cancelAction)
        alertVC.addAction(tomaFoto)
        alertVC.addAction(seleccionaFoto)
        present(alertVC, animated: true, completion: nil)
    }
    
    func muestraLibreriaFotos(){
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .photoLibrary
        imagePicker.allowsEditing = true
        imagePicker.delegate = self
        present(imagePicker, animated: true, completion: nil)
    }
    
    func muestraCamaraDispositivo(){
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .camera
        imagePicker.allowsEditing = true
        imagePicker.delegate = self
        present(imagePicker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        if let imageData = info[UIImagePickerControllerOriginalImage] as? UIImage{
            myImagenGame.image = imageData
            //mySalvarDatosBTN.isEnabled = true
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        
        dismiss(animated: true, completion: nil)
    }
}
