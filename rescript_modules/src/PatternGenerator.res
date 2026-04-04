// SafeBruteForce - Type-Safe Pattern Generation Module
// Written in ReScript for 100% compile-time type safety

// Type definitions for patterns
type pattern = string

type charset = string

type mutationLevel =
  | Minimal
  | Standard
  | Aggressive

type patternType =
  | Charset(charset, int, int)
  | Sequential(int, int)
  | Wordlist(array<string>)
  | Custom(unit => array<pattern>)

// Result type for safe error handling
type result<'a, 'e> =
  | Ok('a)
  | Error('e)

type generatorError =
  | InvalidCharset(string)
  | InvalidRange(string)
  | EmptyWordlist

// Core pattern generation functions

/**
 * Generate all combinations from a charset with length constraints
 * 100% type-safe - compiler guarantees correct types
 */
let generateCharsetCombinations = (
  charset: charset,
  minLength: int,
  maxLength: int,
): result<array<pattern>, generatorError> => {
  if String.length(charset) == 0 {
    Error(InvalidCharset("Charset cannot be empty"))
  } else if minLength < 0 || maxLength < minLength {
    Error(InvalidRange("Invalid length range"))
  } else {
    // Generate all combinations
    let rec generateForLength = (chars: array<string>, length: int): array<pattern> => {
      if length == 0 {
        [""]
      } else {
        let shorter = generateForLength(chars, length - 1)
        Belt.Array.flatMap(chars, char =>
          Belt.Array.map(shorter, suffix => char ++ suffix)
        )
      }
    }

    let charArray = String.split(charset, "")
    let allPatterns = Belt.Array.flatMap(
      Belt.Array.range(minLength, maxLength),
      len => generateForLength(charArray, len)
    )

    Ok(allPatterns)
  }
}

/**
 * Generate sequential number patterns
 * Type-safe integer range validation
 */
let generateSequential = (start: int, end: int): result<array<pattern>, generatorError> => {
  if start > end {
    Error(InvalidRange("Start must be <= end"))
  } else {
    let numbers = Belt.Array.range(start, end)
    let patterns = Belt.Array.map(numbers, n => Int.toString(n))
    Ok(patterns)
  }
}

/**
 * Apply mutations to wordlist
 * Type-safe mutation levels
 */
let applyMutations = (word: string, level: mutationLevel): array<pattern> => {
  let capitalize = (s: string): string => {
    switch String.get(s, 0) {
    | None => s
    | Some(first) =>
      String.toUpperCase(first) ++
      String.slice(s, ~start=1, ~end=String.length(s))
    }
  }

  let leetSpeak = (s: string): string => {
    s
    ->String.replaceRegExp(%re("/a/g"), "4")
    ->String.replaceRegExp(%re("/e/g"), "3")
    ->String.replaceRegExp(%re("/i/g"), "1")
    ->String.replaceRegExp(%re("/o/g"), "0")
    ->String.replaceRegExp(%re("/s/g"), "5")
    ->String.replaceRegExp(%re("/t/g"), "7")
  }

  switch level {
  | Minimal => [word, capitalize(word)]

  | Standard => [
      word,
      capitalize(word),
      word ++ "123",
      word ++ "!",
      word ++ "2024",
      word ++ "2025",
      leetSpeak(word),
    ]

  | Aggressive =>
    Belt.Array.concat(
      [
        word,
        capitalize(word),
        String.toUpperCase(word),
        word ++ "123",
        word ++ "!",
        word ++ "?",
        word ++ "2024",
        word ++ "2025",
        "!" ++ word,
        leetSpeak(word),
      ],
      [
        // Reverse
        String.split(word, "")->Belt.Array.reverse->(arr => String.concatMany("", arr)),
      ]
    )
  }
}

/**
 * Process wordlist with mutations
 * Type-safe array operations
 */
let processWordlist = (
  words: array<string>,
  level: mutationLevel,
): result<array<pattern>, generatorError> => {
  if Belt.Array.length(words) == 0 {
    Error(EmptyWordlist)
  } else {
    let mutated = Belt.Array.flatMap(words, word => applyMutations(word, level))
    Ok(mutated)
  }
}

/**
 * Estimate total patterns
 * Type-safe calculation
 */
let estimateTotal = (patternType: patternType): int => {
  switch patternType {
  | Charset(charset, minLen, maxLen) =>
    let base = String.length(charset)
    let rec sumPowers = (start, end, acc) =>
      if start > end {
        acc
      } else {
        sumPowers(start + 1, end, acc + Math.pow(Int.toFloat(base), ~exp=Int.toFloat(start))->Float.toInt)
      }
    sumPowers(minLen, maxLen, 0)

  | Sequential(start, end) => end - start + 1

  | Wordlist(words) => Belt.Array.length(words)

  | Custom(fn) => Belt.Array.length(fn())
  }
}

/**
 * Common password patterns (built-in)
 * Type-safe constant array
 */
let commonPasswords: array<pattern> = [
  "password",
  "123456",
  "123456789",
  "12345678",
  "12345",
  "qwerty",
  "abc123",
  "password123",
  "admin",
  "letmein",
  "welcome",
  "monkey",
  "dragon",
  "master",
]

// Export interface for Erlang interop
// Type-safe boundary between ReScript and Erlang

/**
 * Generate patterns and return as JSON string for Erlang consumption
 * Type signature guarantees correct input/output types
 */
let generateForErlang = (
  patternType: string,
  config: Js.Json.t,
): result<string, string> => {
  // Parse configuration safely
  switch patternType {
  | "charset" => {
      // Type-safe JSON decoding
      let charset = Js.Json.decodeString(
        Js.Dict.get(Js.Json.decodeObject(config)->Belt.Option.getExn, "charset")
        ->Belt.Option.getExn
      )->Belt.Option.getWithDefault("")

      let minLen = Js.Json.decodeNumber(
        Js.Dict.get(Js.Json.decodeObject(config)->Belt.Option.getExn, "min_length")
        ->Belt.Option.getExn
      )->Belt.Option.getWithDefault(1.0)->Float.toInt

      let maxLen = Js.Json.decodeNumber(
        Js.Dict.get(Js.Json.decodeObject(config)->Belt.Option.getExn, "max_length")
        ->Belt.Option.getExn
      )->Belt.Option.getWithDefault(4.0)->Float.toInt

      switch generateCharsetCombinations(charset, minLen, maxLen) {
      | Ok(patterns) => Ok(Js.Json.stringifyAny(patterns)->Belt.Option.getWithDefault("[]"))
      | Error(InvalidCharset(msg)) => Error("Invalid charset: " ++ msg)
      | Error(InvalidRange(msg)) => Error("Invalid range: " ++ msg)
      | Error(_) => Error("Unknown error")
      }
    }

  | "sequential" => {
      let start = Js.Json.decodeNumber(
        Js.Dict.get(Js.Json.decodeObject(config)->Belt.Option.getExn, "start")
        ->Belt.Option.getExn
      )->Belt.Option.getWithDefault(0.0)->Float.toInt

      let end = Js.Json.decodeNumber(
        Js.Dict.get(Js.Json.decodeObject(config)->Belt.Option.getExn, "end")
        ->Belt.Option.getExn
      )->Belt.Option.getWithDefault(100.0)->Float.toInt

      switch generateSequential(start, end) {
      | Ok(patterns) => Ok(Js.Json.stringifyAny(patterns)->Belt.Option.getWithDefault("[]"))
      | Error(InvalidRange(msg)) => Error("Invalid range: " ++ msg)
      | Error(_) => Error("Unknown error")
      }
    }

  | "common" =>
    Ok(Js.Json.stringifyAny(commonPasswords)->Belt.Option.getWithDefault("[]"))

  | _ => Error("Unknown pattern type: " ++ patternType)
  }
}

// Type-safe validation
let validatePattern = (pattern: pattern, minLength: int, maxLength: int): bool => {
  let len = String.length(pattern)
  len >= minLength && len <= maxLength
}

// Statistics with type safety
type patternStats = {
  totalPatterns: int,
  minLength: int,
  maxLength: int,
  averageLength: float,
}

let calculateStats = (patterns: array<pattern>): patternStats => {
  let total = Belt.Array.length(patterns)
  if total == 0 {
    {totalPatterns: 0, minLength: 0, maxLength: 0, averageLength: 0.0}
  } else {
    let lengths = Belt.Array.map(patterns, String.length)
    let sum = Belt.Array.reduce(lengths, 0, (acc, len) => acc + len)
    let min = Belt.Array.reduce(lengths, 2147483647, (acc, len) => Math.Int.min(acc, len))
    let max = Belt.Array.reduce(lengths, 0, (acc, len) => Math.Int.max(acc, len))

    {
      totalPatterns: total,
      minLength: min,
      maxLength: max,
      averageLength: Int.toFloat(sum) /. Int.toFloat(total),
    }
  }
}
