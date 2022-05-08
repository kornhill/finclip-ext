use std::{sync::Mutex, collections::HashMap};

use once_cell::sync::OnceCell;

type Clip = fn(&String)->String;

fn test(s: &String) -> String {
    println!("invoked with {}", s);
    "ok ".to_string() + s
}

struct Abc {
    map: HashMap<String, Clip>,
}

impl Abc {
    fn new() -> Abc {
        let mut m: HashMap<String, Clip> = HashMap::new();
        m.insert("ok".to_string(), test);
        
        Abc { map: m}
    }

    pub fn test_it(&mut self) {
        self.map.insert("hello".to_string(), test);
        //println!("{:?}", self.map.get(&14).unwrap());
        let func = self.map.get(&"hello".to_string()).unwrap();
        println!("{}", func(&"hello".to_string()));
    }
}

fn global_data() -> &'static Mutex<Abc> {
    static INSTANCE: OnceCell<Mutex<Abc>> = OnceCell::new();
    INSTANCE.get_or_init(|| {
        let m = Abc::new();
        Mutex::new(m)
    })
}

fn main() {
    let mut g = global_data().lock().unwrap();
    //println!("{:?}", g.map.get(&13).unwrap());
    g.test_it();
}