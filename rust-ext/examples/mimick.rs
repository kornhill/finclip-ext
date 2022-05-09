use std::ffi::{CStr, CString};
use std::collections::HashMap;
use finclipext::{finclip_init, finclip_set, finclip_api_name, finclip_call, finclip_release};
use serde_json::json;

type FinClipCall = fn(&String) -> String;

fn api_drinker(input: &String) -> String {
    println!("invoked with parameter {}", input);
    
    let john = json!({
        "name": "john doe",
        "phones": "1234567"
    });

    john.to_string()
}

fn api_whisky(input: &String) -> String {
    println!("invoked with parameter {}", input);
    
    let brands = json!({
        "whisky": {
            "jack": "daniel",
            "johny": "walker",
            "henry": "Mckenna",
            "suntory": "toki"
        }
    });

    brands.to_string()
}


#[no_mangle]
pub unsafe extern "C" fn myext_register_apis() -> *mut HashMap<String, FinClipCall> {
    let mut map: HashMap<String, FinClipCall> = HashMap::new();
    map.insert("api_drinker".to_string(), api_drinker);
    map.insert("api_whisky".to_string(), api_whisky);

    Box::into_raw(Box::new(map))
}

#[no_mangle]
pub unsafe extern "C" fn myext_release(ptr: *mut HashMap<String, FinClipCall>) {
    if !ptr.is_null() {
        drop(ptr);
    }
}

fn main() {
    unsafe {
        let map = myext_register_apis();
        finclip_init(map);

        println!("api set size: {}", finclip_set());
        for i in 0..finclip_set() {
            let cname = finclip_api_name(i);

            // use method name as parameter
            let input = CStr::from_ptr(cname);
            let p = input.to_str().unwrap();
            let input = json!({"method": p});
            println!("input param: {}", &input);
            let cstr = CString::new(input.to_string()).unwrap();
            let cinput = cstr.as_ptr();

            let coutput = finclip_call(cname, cinput );
            let output = CStr::from_ptr(coutput);
            let p = output.to_str().unwrap();
            println!("invoking result: {}", p);

            finclip_release(cname);
            finclip_release(coutput);
        }

        myext_release(map);
    }
}

