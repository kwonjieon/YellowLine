import UIKit

class ViewController: UIViewController {

    @IBAction func moveToSearch(_ sender: Any) {
        guard let nextVC = self.storyboard?.instantiateViewController(identifier: "SearchDestinationViewController") else {return}
        nextVC.modalPresentationStyle = UIModalPresentationStyle.fullScreen
          self.present(nextVC, animated: true)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }


}
