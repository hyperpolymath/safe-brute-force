//! SafeBruteForce Rust NIF - High-Performance Pattern Generation
//!
//! This module provides 100% type-safe and memory-safe pattern generation
//! using Rust's compile-time guarantees and zero-cost abstractions.
//!
//! # Type Safety
//! - All types checked at compile time
//! - No null pointers (Option<T> instead)
//! - No buffer overflows (bounds checked)
//! - No data races (ownership system)
//!
//! # Memory Safety
//! - No manual memory management
//! - No use-after-free
//! - No double-free
//! - Automatic cleanup (RAII)

#![forbid(unsafe_code)]
use rustler::{Encoder, Env, Error, Term};
use serde::{Deserialize, Serialize};
use rayon::prelude::*;

mod atoms {
    rustler::atoms! {
        ok,
        error,
        invalid_charset,
        invalid_range,
        empty_wordlist,
    }
}

/// Pattern type - guaranteed to be valid UTF-8
type Pattern = String;

/// Charset for generation - validated at construction
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Charset(String);

impl Charset {
    /// Create new charset with validation
    pub fn new(s: impl Into<String>) -> Result<Self, &'static str> {
        let s = s.into();
        if s.is_empty() {
            Err("Charset cannot be empty")
        } else {
            Ok(Charset(s))
        }
    }

    /// Get characters as slice
    pub fn chars(&self) -> impl Iterator<Item = char> + '_ {
        self.0.chars()
    }

    /// Get length
    pub fn len(&self) -> usize {
        self.0.chars().count()
    }
}

/// Mutation level - type-safe enum
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum MutationLevel {
    Minimal,
    Standard,
    Aggressive,
}

/// Pattern generation result - explicit error handling
pub type Result<T> = std::result::Result<T, GeneratorError>;

/// Generator errors - exhaustive and type-safe
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum GeneratorError {
    InvalidCharset(String),
    InvalidRange(String),
    EmptyWordlist,
}

/// Generate all combinations from charset with length constraints
///
/// # Type Safety
/// - `charset`: Validated Charset type (not raw string)
/// - `min_length`: usize (cannot be negative)
/// - `max_length`: usize (cannot be negative)
/// - Returns: Result<Vec<Pattern>, GeneratorError> (explicit error handling)
///
/// # Memory Safety
/// - No buffer overflows (Vec auto-grows)
/// - No use-after-free (ownership tracked)
/// - No data races (immutable by default)
pub fn generate_charset_combinations(
    charset: &Charset,
    min_length: usize,
    max_length: usize,
) -> Result<Vec<Pattern>> {
    if min_length > max_length {
        return Err(GeneratorError::InvalidRange(
            format!("min_length ({}) > max_length ({})", min_length, max_length)
        ));
    }

    let chars: Vec<char> = charset.chars().collect();
    let mut all_patterns = Vec::new();

    for length in min_length..=max_length {
        all_patterns.extend(generate_for_length(&chars, length));
    }

    Ok(all_patterns)
}

/// Generate patterns of exact length (internal helper)
fn generate_for_length(chars: &[char], length: usize) -> Vec<Pattern> {
    if length == 0 {
        return vec![String::new()];
    }

    let shorter = generate_for_length(chars, length - 1);

    chars
        .iter()
        .flat_map(|&c| {
            shorter.iter().map(move |suffix| {
                let mut s = String::with_capacity(length);
                s.push(c);
                s.push_str(suffix);
                s
            })
        })
        .collect()
}

/// Generate sequential patterns in parallel
///
/// # Performance
/// Uses Rayon for parallel generation on multi-core systems
///
/// # Type Safety
/// - Range is validated (start <= end)
/// - usize prevents negative numbers
pub fn generate_sequential_parallel(
    start: usize,
    end: usize,
) -> Result<Vec<Pattern>> {
    if start > end {
        return Err(GeneratorError::InvalidRange(
            format!("start ({}) > end ({})", start, end)
        ));
    }

    // Parallel generation using Rayon
    let patterns: Vec<Pattern> = (start..=end)
        .into_par_iter()  // Parallel iterator
        .map(|n| n.to_string())
        .collect();

    Ok(patterns)
}

/// Apply mutations to a word with type-safe level
///
/// # Type Safety
/// - MutationLevel is an enum (exhaustive matching)
/// - Cannot pass invalid level
pub fn apply_mutations(word: &str, level: MutationLevel) -> Vec<Pattern> {
    let capitalize = |s: &str| -> String {
        let mut chars = s.chars();
        match chars.next() {
            None => String::new(),
            Some(first) => first.to_uppercase().chain(chars).collect(),
        }
    };

    let leet_speak = |s: &str| -> String {
        s.chars()
            .map(|c| match c {
                'a' | 'A' => '4',
                'e' | 'E' => '3',
                'i' | 'I' => '1',
                'o' | 'O' => '0',
                's' | 'S' => '5',
                't' | 'T' => '7',
                _ => c,
            })
            .collect()
    };

    let reverse = |s: &str| -> String {
        s.chars().rev().collect()
    };

    // Exhaustive match - compiler ensures all levels handled
    match level {
        MutationLevel::Minimal => {
            vec![word.to_string(), capitalize(word)]
        }
        MutationLevel::Standard => {
            vec![
                word.to_string(),
                capitalize(word),
                format!("{}123", word),
                format!("{}!", word),
                format!("{}2024", word),
                format!("{}2025", word),
                leet_speak(word),
            ]
        }
        MutationLevel::Aggressive => {
            vec![
                word.to_string(),
                capitalize(word),
                word.to_uppercase(),
                format!("{}123", word),
                format!("{}!", word),
                format!("{}?", word),
                format!("{}2024", word),
                format!("{}2025", word),
                format!("!{}", word),
                leet_speak(word),
                reverse(word),
                format!("{}{}", word, reverse(word)),
            ]
        }
    }
}

/// Process wordlist with mutations in parallel
///
/// # Performance
/// Uses Rayon for parallel mutation application
///
/// # Type Safety
/// - Empty wordlist returns error (not panic)
/// - MutationLevel is type-checked
pub fn process_wordlist_parallel(
    words: &[String],
    level: MutationLevel,
) -> Result<Vec<Pattern>> {
    if words.is_empty() {
        return Err(GeneratorError::EmptyWordlist);
    }

    // Parallel mutation application
    let mutated: Vec<Pattern> = words
        .par_iter()
        .flat_map(|word| apply_mutations(word, level))
        .collect();

    Ok(mutated)
}

/// Validate pattern against constraints
///
/// # Type Safety
/// - usize prevents negative lengths
/// - Returns bool (not int/null)
pub fn validate_pattern(pattern: &str, min_length: usize, max_length: usize) -> bool {
    let len = pattern.len();
    len >= min_length && len <= max_length
}

/// Pattern statistics - type-safe struct
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct PatternStats {
    pub total_patterns: usize,
    pub min_length: usize,
    pub max_length: usize,
    pub average_length: f64,
    pub unique_patterns: usize,
}

/// Calculate statistics with zero-copy iteration
pub fn calculate_stats(patterns: &[Pattern]) -> PatternStats {
    if patterns.is_empty() {
        return PatternStats {
            total_patterns: 0,
            min_length: 0,
            max_length: 0,
            average_length: 0.0,
            unique_patterns: 0,
        };
    }

    let lengths: Vec<usize> = patterns.iter().map(|p| p.len()).collect();
    let sum: usize = lengths.iter().sum();
    let min = *lengths.iter().min().unwrap_or(&0);
    let max = *lengths.iter().max().unwrap_or(&0);

    // Calculate unique patterns
    let mut unique_set = std::collections::HashSet::new();
    for pattern in patterns {
        unique_set.insert(pattern);
    }

    PatternStats {
        total_patterns: patterns.len(),
        min_length: min,
        max_length: max,
        average_length: sum as f64 / patterns.len() as f64,
        unique_patterns: unique_set.len(),
    }
}

//=============================================================================
// Rustler NIF Exports - Bridge to Erlang
//=============================================================================

rustler::init!("Elixir.SbfNif", [
    generate_charset_combinations_nif,
    generate_sequential_parallel_nif,
    process_wordlist_parallel_nif,
    apply_mutations_nif,
    calculate_stats_nif,
]);

/// NIF: Generate charset combinations
#[rustler::nif]
fn generate_charset_combinations_nif(
    env: Env,
    charset_str: String,
    min_length: usize,
    max_length: usize,
) -> Result<Vec<String>, Error> {
    let charset = Charset::new(charset_str)
        .map_err(|e| Error::Term(Box::new(e)))?;

    generate_charset_combinations(&charset, min_length, max_length)
        .map_err(|e| Error::Term(Box::new(format!("{:?}", e))))
}

/// NIF: Generate sequential patterns in parallel
#[rustler::nif]
fn generate_sequential_parallel_nif(
    env: Env,
    start: usize,
    end: usize,
) -> Result<Vec<String>, Error> {
    generate_sequential_parallel(start, end)
        .map_err(|e| Error::Term(Box::new(format!("{:?}", e))))
}

/// NIF: Process wordlist with mutations in parallel
#[rustler::nif]
fn process_wordlist_parallel_nif(
    env: Env,
    words: Vec<String>,
    level: String,
) -> Result<Vec<String>, Error> {
    let mutation_level = match level.as_str() {
        "minimal" => MutationLevel::Minimal,
        "standard" => MutationLevel::Standard,
        "aggressive" => MutationLevel::Aggressive,
        _ => return Err(Error::BadArg),
    };

    process_wordlist_parallel(&words, mutation_level)
        .map_err(|e| Error::Term(Box::new(format!("{:?}", e))))
}

/// NIF: Apply mutations to single word
#[rustler::nif]
fn apply_mutations_nif(
    env: Env,
    word: String,
    level: String,
) -> Result<Vec<String>, Error> {
    let mutation_level = match level.as_str() {
        "minimal" => MutationLevel::Minimal,
        "standard" => MutationLevel::Standard,
        "aggressive" => MutationLevel::Aggressive,
        _ => return Err(Error::BadArg),
    };

    Ok(apply_mutations(&word, mutation_level))
}

/// NIF: Calculate pattern statistics
#[rustler::nif]
fn calculate_stats_nif(env: Env, patterns: Vec<String>) -> PatternStats {
    calculate_stats(&patterns)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_charset_validation() {
        assert!(Charset::new("abc").is_ok());
        assert!(Charset::new("").is_err());
    }

    #[test]
    fn test_generate_combinations() {
        let charset = Charset::new("ab").unwrap();
        let patterns = generate_charset_combinations(&charset, 1, 2).unwrap();
        assert_eq!(patterns.len(), 6); // a, b, aa, ab, ba, bb
    }

    #[test]
    fn test_sequential_generation() {
        let patterns = generate_sequential_parallel(1, 5).unwrap();
        assert_eq!(patterns.len(), 5);
        assert_eq!(patterns[0], "1");
        assert_eq!(patterns[4], "5");
    }

    #[test]
    fn test_mutations() {
        let patterns = apply_mutations("test", MutationLevel::Minimal);
        assert_eq!(patterns.len(), 2);
        assert!(patterns.contains(&"test".to_string()));
        assert!(patterns.contains(&"Test".to_string()));
    }
}
