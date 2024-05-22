import UIKit
class SearchDestinationVC: UIViewController{
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var listTableView: UITableView!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
      
        self.view.backgroundColor = UIColor(red: 0.11, green: 0.11, blue: 0.11, alpha: 1.00)
        setNaviBar()
        setSearchBar()
        
    }
    
    func setSearchBar() {
        
        
        /*
         searchBar.translatesAutoresizingMaskIntoConstraints = false
        searchBar.widthAnchor.constraint(equalToConstant: 356).isActive = true
        searchBar.heightAnchor.constraint(equalToConstant: 149).isActive = true
        searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        */
        
        searchBar.placeholder = "목적지를 입력해주세요"
        //searchBar.setImage(UIImage(named: "search-icon"), for: UISearchBar.Icon.search, state: .normal)
        searchBar.backgroundImage = UIImage()
        if let textfield = searchBar.value(forKey: "searchField") as? UITextField {
            textfield.backgroundColor = UIColor.white
            textfield.textColor = UIColor.black
        }
    }
    
    func setNaviBar() {
        // safe area
        var statusBarHeight: CGFloat = 0
        statusBarHeight = UIApplication.shared.windows.first?.safeAreaInsets.top ?? 0
        
        // navigationBar
        let naviBar = UINavigationBar(frame: .init(x: 0, y: statusBarHeight, width: view.frame.width, height: statusBarHeight))
        naviBar.isTranslucent = false
        
        // 네비게이션 바의 배경 이미지를 설정하여 둥근 모서리를 표현
        if let backgroundImage = UIImage(named: "SearchNaviBar") {
            naviBar.setBackgroundImage(backgroundImage, for: .default)
        }
        
        let naviItem = UINavigationItem(title: "title")
        naviItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(test))
        naviBar.items = [naviItem]
        
        view.addSubview(naviBar)
    }
    
    @objc func test() {
        print("click")
    }
}

