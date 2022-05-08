use std::os::raw::{c_uint, c_char};
use std::{sync::Mutex, collections::HashMap};
use once_cell::sync::OnceCell;
use std::ffi::{CString, CStr};

type FinClipCall = fn(&String) -> String;
pub struct FinClipExtApiSet {
    registry: HashMap<String, FinClipCall>,
}

impl FinClipExtApiSet {
    pub fn new() -> FinClipExtApiSet {
        let reg: HashMap<String, FinClipCall> = HashMap::new();
        FinClipExtApiSet{
            registry: reg,
        }
    }

    pub fn register(&mut self, api_name: String, api: FinClipCall) {
        self.registry.insert(api_name, api);
    }

    pub fn invoke(&self, api_name: &String, input_json: &String) -> String {
        let api = self.registry.get(api_name).unwrap();
        api(input_json)
        
        // match api {
        //     Some(api) => api.unwrap()(input_json),
        //     None => {
        //         "{}".to_string()
        //     }
        // }
    }

}

pub fn finclip() -> &'static Mutex<FinClipExtApiSet> {
    static INSTANCE: OnceCell<Mutex<FinClipExtApiSet>> = OnceCell::new();
    INSTANCE.get_or_init(|| {
        let m = FinClipExtApiSet::new();
        Mutex::new(m)
    })
}

pub fn register(api_name: String, api: FinClipCall) {
    let mut f = finclip().lock().unwrap();
    f.register(api_name, api);
    drop(f);
}

#[no_mangle]
pub unsafe extern "C" fn finclip_set() -> c_uint {
    let api_set = finclip().lock().unwrap();
    let size = api_set.registry.len();
    drop(api_set);
    size as u32
}

#[no_mangle]
pub extern "C" fn finclip_api_name(index: c_uint) -> *mut c_char {
    let api_set = finclip().lock().unwrap();
    let name = api_set.registry.keys().nth(index as usize).unwrap(); 
    let cstr = CString::new(name.as_str()).unwrap();
    drop(api_set); 
    cstr.into_raw()
}

#[no_mangle]
pub unsafe extern "C" fn finclip_call(api_name: *const c_char, _input: *const c_char) -> *mut c_char {

    let ptr = CStr::from_ptr(api_name);
    let rust_api_name = ptr.to_str().unwrap().to_string();

    let ptr_input = CStr::from_ptr(_input);
    let rust_input = ptr_input.to_str().unwrap().to_string();
    
    let api_set = finclip().lock().unwrap();
    let output = api_set.invoke(&rust_api_name, &rust_input);
    std::mem::drop(api_set);
    
    let cstr = CString::new(output).unwrap();
    cstr.into_raw()
}

#[no_mangle]
pub unsafe extern "C" fn finclip_release(data: *mut c_char) {
    drop(CString::from_raw(data));
}