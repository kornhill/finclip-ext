use std::ffi::{CStr, CString};
use finclipext::{register, finclip_set, finclip_api_name, finclip_call, finclip_release};
use serde_json::{json};


fn invoke(input: &String) -> String {
    println!("invoked with parameter {}", input);
    
    let john = json!({
        "name": "john doe",
        "phones": "1234567"
    });

    john.to_string()
}


fn main() {
    unsafe {

        // register a call named "hello" pointing to 'invoke' function
        register("hello".to_string(), invoke);
        println!("API set size: {}", finclip_set());

        // retrieve the call name
        let cname = finclip_api_name(0);

        // prepare an input parameter for the call
        let input = "{}";
        let cstr = CString::new(input).unwrap();
        let cinput = cstr.as_ptr();

        // this is how the C-style call is initiated from foreign side (ObjC, Java etc)
        let coutput = finclip_call(cname, cinput);

        // verify the result
        let output = CStr::from_ptr(coutput);
        let p = output.to_str().unwrap();
        println!("invoking result: {}", p);

        finclip_release(cname);
        finclip_release(coutput);
    }
}
