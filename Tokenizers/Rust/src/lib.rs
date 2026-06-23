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

        fn enable_fixing_length(&mut self, length: usize, padding_token: &str) -> Result<bool>;

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
    fn enable_fixing_length(
        &mut self,
        length: usize,
        padding_token: &str,
    ) -> Result<bool, Box<dyn std::error::Error>> {
        let padding_id: u32 = match self.0.token_to_id(padding_token) {
            None => return Ok(false),
            Some(id) => id,
        };

        let padding_params = tokenizers::PaddingParams {
            strategy: tokenizers::PaddingStrategy::Fixed(length),
            pad_token: padding_token.into(),
            pad_id: padding_id,
            ..Default::default()
        };

        self.0.with_padding(Some(padding_params));

        let truncation_params = tokenizers::TruncationParams {
            max_length: length,
            ..Default::default()
        };
        return match self.0.with_truncation(Some(truncation_params)) {
            Ok(_) => Ok(true),
            Err(error) => Err(error),
        };
    }
}

impl Tokenizer {
    pub fn encode(
        &self,
        text: &str,
    ) -> Result<tokenizers_bridge::Encoding, Box<dyn std::error::Error>> {
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
