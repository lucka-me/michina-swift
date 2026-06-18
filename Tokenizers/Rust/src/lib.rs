#[cxx::bridge(namespace = "tokenizers_bridge::rust")]
mod tokenizers_bridge {
    struct Encoding {
        ids: Vec<u32>,
        attention_mask: Vec<u32>,
    }

    extern "Rust" {
        type Tokenizer;

        #[Self = "Tokenizer"]
        fn from_file(path: &str) -> Result<Box<Tokenizer>>;
        fn encode(&self, text: &str) -> Result<Encoding>;
    }
}

pub struct Tokenizer(tokenizers::Tokenizer);

impl Tokenizer {
    fn from_file(path: &str) -> Result<Box<Self>, Box<dyn std::error::Error>> {
        let tokenizer = match tokenizers::Tokenizer::from_file(path) {
            Ok(tokenizer) => tokenizer,
            Err(error) => return Err(error),
        };
        Ok(Box::new(Tokenizer(tokenizer)))
    }
}

impl Tokenizer {
    pub fn encode(&self, text: &str) -> Result<tokenizers_bridge::Encoding, Box<dyn std::error::Error>> {
        let encoding = match self.0.encode(text, true) {
            Ok(encoding) => encoding,
            Err(error) => return Err(error),
        };
        Ok(tokenizers_bridge::Encoding {
            ids: encoding.get_ids().to_vec(),
            attention_mask: encoding.get_attention_mask().to_vec(),
        })
    }
}
