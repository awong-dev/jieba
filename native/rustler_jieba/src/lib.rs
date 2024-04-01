use lazy_static::lazy_static;

use jieba_rs::{Error as JiebaError, Jieba, KeywordExtract, TextRank, TokenizeMode, TFIDF};
use rustler::{
    types::tuple, Encoder, Env, Error as RustlerError, NifStruct, NifUnitEnum, ResourceArc, Term,
};

use std::fs::File;
use std::io::BufReader;
use std::io::Error as IoError;
use std::io::ErrorKind as IoErrorKind;
use std::sync::Mutex;

// Creates an atoms module using the rustler macro
mod atoms {
    rustler::atoms! {
        ok,

        // Posix
        enoent, // File does not exist
        eacces, // Permission denied
        epipe, // Broken pipe
        eexist, // File exists

        io_unknown // Other error
    }
}

#[derive(NifUnitEnum)]
enum TokenizeEnum {
    Default,
    Search,
}

pub struct JiebaResource {
    jieba_rs: Mutex<Jieba>,
}

#[derive(NifStruct)]
#[module = "Jieba"]
struct ElixirJieba {
    pub use_default: bool,
    pub dict_paths: Vec<String>,
    pub native: ResourceArc<JiebaResource>,
}

#[derive(NifStruct)]
#[module = "Jieba.Keyword"]
struct JiebaKeyword {
    pub keyword: String,
    pub weight: f64,
}

#[derive(NifStruct)]
#[module = "Jieba.Tag"]
struct JiebaTag {
    pub word: String,
    pub tag: String,
}

#[derive(NifStruct)]
#[module = "Jieba.Token"]
struct JiebaToken {
    pub word: String,
    pub start: usize,
}

fn on_load(env: Env, _term: Term) -> bool {
    rustler::resource!(JiebaResource, env);
    true
}

// Translates std library errors into Rustler atoms
fn io_error_to_rustler_error(err: IoError) -> RustlerError {
    let atom = match err.kind() {
        IoErrorKind::NotFound => atoms::enoent(),
        IoErrorKind::PermissionDenied => atoms::eacces(),
        IoErrorKind::BrokenPipe => atoms::epipe(),
        IoErrorKind::AlreadyExists => atoms::eexist(),
        _ => atoms::io_unknown(),
    };
    RustlerError::Term(Box::new(atom))
}

fn jieba_error_to_rustler_error(jieba_err: JiebaError) -> RustlerError {
    match jieba_err {
        JiebaError::Io(io_err) => io_error_to_rustler_error(io_err),
        JiebaError::InvalidDictEntry(entry) => RustlerError::Term(Box::new(entry)),
    }
}

#[rustler::nif]
fn native_new() -> ElixirJieba {
    ElixirJieba {
        use_default: true,
        dict_paths: Vec::new(),
        native: ResourceArc::new(JiebaResource {
            jieba_rs: Mutex::new(Jieba::new()),
        }),
    }
}

#[rustler::nif]
fn native_empty() -> ElixirJieba {
    ElixirJieba {
        use_default: false,
        dict_paths: Vec::new(),
        native: ResourceArc::new(JiebaResource {
            jieba_rs: Mutex::new(Jieba::empty()),
        }),
    }
}

#[rustler::nif]
fn clone(jieba: ElixirJieba) -> ElixirJieba {
    let jieba_rs = jieba.native.jieba_rs.lock().unwrap();
    ElixirJieba {
        use_default: jieba.use_default,
        dict_paths: jieba.dict_paths.clone(),
        native: ResourceArc::new(JiebaResource {
            jieba_rs: Mutex::new(jieba_rs.clone()),
        }),
    }
}

#[rustler::nif]
fn load_dict(
    env: Env,
    in_jieba: ElixirJieba,
    dict_path: String,
) -> Result<Term, RustlerError> {
    let file = File::open(&dict_path).map_err(io_error_to_rustler_error)?;
    let mut jieba = in_jieba;
    {
        let jieba_rs = &mut jieba.native.jieba_rs.lock().unwrap();
        let mut reader = BufReader::new(file);
        jieba_rs
            .load_dict(&mut reader)
            .map_err(jieba_error_to_rustler_error)?;
        jieba.dict_paths.push(dict_path);
    }
    let ok_atom_term = atoms::ok().encode(env);
    Ok(tuple::make_tuple(env, &[ok_atom_term, jieba.encode(env)]))
}

#[rustler::nif]
fn suggest_freq(jieba: ElixirJieba, segment: String) -> usize {
    jieba.native.jieba_rs.lock().unwrap().suggest_freq(&segment)
}

#[rustler::nif]
fn add_word(jieba: ElixirJieba, word: String, freq: Option<usize>, new_tag: Option<&str>) -> usize {
    jieba
        .native
        .jieba_rs
        .lock()
        .unwrap()
        .add_word(&word, freq, new_tag)
}

#[rustler::nif]
fn native_cut(jieba: ElixirJieba, sentence: String, hmm: bool) -> Vec<String> {
    jieba
        .native
        .jieba_rs
        .lock()
        .unwrap()
        .cut(&sentence, hmm)
        .into_iter()
        .map(|s| s.to_string())
        .collect()
}

lazy_static! {
    static ref STATIC_JIEBA: Jieba = Jieba::new();
}

#[rustler::nif]
fn native_static_cut(sentence: String) -> Vec<String> {
    STATIC_JIEBA
        .cut(&sentence, false)
        .into_iter()
        .map(|s| s.to_string())
        .collect()
}

#[rustler::nif]
fn cut_all(jieba: ElixirJieba, sentence: String) -> Vec<String> {
    jieba
        .native
        .jieba_rs
        .lock()
        .unwrap()
        .cut_all(&sentence)
        .into_iter()
        .map(|s| s.to_string())
        .collect()
}

#[rustler::nif]
fn cut_for_search(jieba: ElixirJieba, sentence: String, hmm: bool) -> Vec<String> {
    jieba
        .native
        .jieba_rs
        .lock()
        .unwrap()
        .cut_for_search(&sentence, hmm)
        .into_iter()
        .map(|s| s.to_string())
        .collect()
}

#[rustler::nif]
fn tokenize(
    jieba: ElixirJieba,
    sentence: String,
    mode: TokenizeEnum,
    hmm: bool,
) -> Vec<JiebaToken> {
    jieba
        .native
        .jieba_rs
        .lock()
        .unwrap()
        .tokenize(
            &sentence,
            match mode {
                TokenizeEnum::Default => TokenizeMode::Default,
                TokenizeEnum::Search => TokenizeMode::Search,
            },
            hmm,
        )
        .into_iter()
        .map(|t| JiebaToken {
            word: t.word.to_string(),
            start: t.start,
        })
        .collect()
}

#[rustler::nif]
fn tag(jieba: ElixirJieba, sentence: String, hmm: bool) -> Vec<JiebaTag> {
    jieba
        .native
        .jieba_rs
        .lock()
        .unwrap()
        .tag(&sentence, hmm)
        .into_iter()
        .map(|t| JiebaTag {
            word: t.word.to_string(),
            tag: t.tag.to_string(),
        })
        .collect()
}

#[rustler::nif]
fn tfidf_extract_tags(
    env: Env<'_>,
    jieba: ElixirJieba,
    sentence: String,
    top_k: usize,
    allowed_pos: Vec<String>,
    tfidf_dict_path: String,
    stop_words: Vec<String>,
) -> Result<Term<'_>, RustlerError> {
    let jieba = jieba.native.jieba_rs.lock().unwrap();
    let mut keyword_extractor = TFIDF::new_with_jieba(&jieba);

    if !tfidf_dict_path.is_empty() {
        let file = File::open(&tfidf_dict_path).map_err(io_error_to_rustler_error)?;
        let mut reader = BufReader::new(file);
        keyword_extractor
            .load_dict(&mut reader)
            .map_err(io_error_to_rustler_error)?;
    }

    for word in stop_words.into_iter() {
        keyword_extractor.add_stop_word(word);
    }

    let result: Vec<JiebaKeyword> = keyword_extractor
        .extract_tags(&sentence, top_k, allowed_pos)
        .into_iter()
        .map(|e| JiebaKeyword {
            keyword: e.keyword.to_string(),
            weight: e.weight,
        })
        .collect();

    let ok_atom_term = atoms::ok().encode(env);
    Ok(tuple::make_tuple(env, &[ok_atom_term, result.encode(env)]))
}

#[rustler::nif]
fn textrank_extract_tags(
    env: Env<'_>,
    jieba: ElixirJieba,
    sentence: String,
    top_k: usize,
    allowed_pos: Vec<String>,
    stop_words: Vec<String>,
) -> Result<Term<'_>, RustlerError> {
    let jieba = jieba.native.jieba_rs.lock().unwrap();
    let mut keyword_extractor = TextRank::new_with_jieba(&jieba);

    for word in stop_words.into_iter() {
        keyword_extractor.add_stop_word(word);
    }

    let result: Vec<JiebaKeyword> = keyword_extractor
        .extract_tags(&sentence, top_k, allowed_pos)
        .into_iter()
        .map(|e| JiebaKeyword {
            keyword: e.keyword.to_string(),
            weight: e.weight,
        })
        .collect();

    let ok_atom_term = atoms::ok().encode(env);
    Ok(tuple::make_tuple(env, &[ok_atom_term, result.encode(env)]))
}

rustler::init!(
    "Elixir.Jieba",
    [
        native_new,
        native_empty,
        clone,
        load_dict,
        suggest_freq,
        add_word,
        native_cut,
        native_static_cut,
        cut_all,
        cut_for_search,
        tokenize,
        tag,
        tfidf_extract_tags,
        textrank_extract_tags
    ],
    load = on_load
);
