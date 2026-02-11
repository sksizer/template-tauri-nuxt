// Learn more about Tauri commands at https://tauri.app/develop/calling-rust/
#[tauri::command]
fn echo(message: &str) -> String {
    format!("Echo from Rust: {}", message)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn echo_returns_expected_message() {
        let result = echo("Hello World");
        assert_eq!(result, "Echo from Rust: Hello World");
    }
}

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    tauri::Builder::default()
        .plugin(tauri_plugin_opener::init())
        .invoke_handler(tauri::generate_handler![echo])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
