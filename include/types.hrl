%% Type specifications for SafeBruteForce modules
%% These specs are used by Dialyzer for static type analysis

%% Common types
-type pattern() :: string().
-type result() :: 'success' | 'failure'.
-type state_name() :: 'running' | 'paused' | 'waiting_confirmation' | 'stopped'.
-type error_reason() :: atom() | {atom(), term()}.

%% sbf_state types
-type state_data() :: #{
    pause_interval => pos_integer(),
    safety_enabled => boolean(),
    attempt_count => non_neg_integer(),
    success_count => non_neg_integer(),
    failure_count => non_neg_integer(),
    start_time => integer(),
    last_attempt_time => integer(),
    current_batch => non_neg_integer(),
    successful_patterns => [pattern()],
    checkpoint_id => binary() | 'undefined'
}.

-type status() :: #{
    state => state_name(),
    attempts => non_neg_integer(),
    successes => non_neg_integer()
}.

-type stats() :: #{
    state => state_name(),
    attempt_count => non_neg_integer(),
    success_count => non_neg_integer(),
    failure_count => non_neg_integer(),
    successful_patterns => [pattern()],
    elapsed_seconds => non_neg_integer(),
    attempts_per_second => float(),
    success_rate_percent => float(),
    current_batch => non_neg_integer(),
    pause_interval => pos_integer(),
    safety_enabled => boolean()
}.

%% sbf_patterns types
-type charset() :: string().
-type pattern_type() :: 'wordlist' | 'charset' | 'sequential' | 'common' | 'custom'.
-type mutation_level() :: 'minimal' | 'standard' | 'aggressive'.

%% sbf_executor types
-type target_type() :: 'http' | 'function' | 'mock' | 'ssh'.
-type http_method() :: 'get' | 'post'.
-type body_format() :: 'urlencoded' | 'json'.

-type target_config() :: [
    {type, target_type()} |
    {url, string()} |
    {method, http_method()} |
    {username, string()} |
    {username_field, string()} |
    {password_field, string()} |
    {success_pattern, string()} |
    {failure_pattern, string()} |
    {body_format, body_format()} |
    {headers, [{string(), string()}]} |
    {function, fun((pattern()) -> boolean())} |
    {expected, pattern()}
].

-type attempt_result() ::
    {ok, result(), map()} |
    {error, error_reason()}.

%% sbf_checkpoint types
-type checkpoint_id() :: string().
-type checkpoint_data() :: #{
    version => string(),
    timestamp => integer(),
    state => state_data(),
    metadata => map()
}.

-type checkpoint_info() :: #{
    session => atom(),
    checkpoint_id => checkpoint_id(),
    filename => string(),
    timestamp => integer()
}.

%% sbf_progress types
-type progress() :: #{
    total => non_neg_integer(),
    current => non_neg_integer(),
    start_time => integer(),
    last_update => integer(),
    last_current => non_neg_integer()
}.

-type eta() :: non_neg_integer() | 'unknown'.

%% sbf_logger types
-type log_level() :: 'debug' | 'info' | 'warning' | 'error' | 'success' | 'failure'.
-type log_metadata() :: map().
