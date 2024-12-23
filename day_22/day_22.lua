-- Day 22
package.path = '../utils/?.lua;' .. package.path
local utils = require "utils"

input_str = utils.file_to_string("input.txt")
ex_str = "1\n"
      .. "10\n"
      .. "100\n"
      .. "2024\n"

-- # Parsing
function parse_initial_codes (str)
  local codes = {}
  for line in utils.lines(str) do
    table.insert(codes, tonumber(line))
  end
  return codes
end

ex_codes = parse_initial_codes(ex_str)
print("Example initial codes: ", table.concat(ex_codes, ' '))
input_codes = parse_initial_codes(input_str)

-- # Part 1
-- This part can be simulated. But I expect the next part to require
-- looking for some kind of arithmetic.

-- Mix operation between the secret number and another number
function mix (secret, num)
  return secret ~ num
end

print("Mix 42 and 15: ", mix(42, 15))

-- Prune the secret number
function prune (secret)
  local num = math.fmod(secret, 16777216)
  num = math.floor(num + 0.5)
  return num
end

print("Prune 100000000: ", prune(100000000))

-- Multiply a number by 64 (bitshift left by 6)
function mul64 (num)
  return num << 6
end

print("5 x 64 = ", 5*64, mul64(5))

-- Divide by 32 (bitshift right by 5)
function div32 (num)
  return num >> 5
end

print("928 / 32 = ", 928 / 32, div32(928))

-- Multiply by 2048 (bitshift left by 11)
function mul2048 (num)
  return num << 11
end

print("2 * 2048 = ", 2*2048, mul2048(2))

-- Compute the next secret number from the current one.
function next_secret(secret)
  local new_secret = secret
  local num = new_secret << 6
  new_secret = mix(new_secret, num)
  new_secret = prune(new_secret)
  num = new_secret >> 5
  new_secret = mix(new_secret, num)
  new_secret = prune(new_secret)
  num = new_secret << 11
  new_secret = mix(new_secret, num)
  new_secret = prune(new_secret)
  return new_secret
end

-- Compute the secret obtained after n iterations
function secret_n (secret, n)
  local new_secret = secret
  for i = 1, n do
    new_secret = next_secret(new_secret)
  end
  return new_secret
end

for i = 1, #ex_codes do
print("Example ", ex_codes[i], " 2000 secret: ", secret_n(ex_codes[i], 2000))
end

-- Sum secrets after n iterations.
function accum_secrets_n (secrets, n)
  local count = 0
  for _, secret in ipairs(secrets) do
    local secret = secret_n(secret, n)
    count = count + secret
  end
  return count
end

print("Example part 1 result: ", accum_secrets_n(ex_codes, 2000))
print("Part 1 result: ", accum_secrets_n(input_codes, 2000))

-- # Part 2
-- It is conceivable to try every possible combination of (d1, d2, d3, d4)
-- with pruning along the way.
-- The following necessary conditions apply
-- * Vi in [1, 4], -9 <= di <= 9 (19 possibilities)
-- * d1 + d2 + d3 + d4 >= 0, otherwise we are just buying at a lower price
--                           than what we available before the sequence
-- * d1 + d2, d2 + d3, d3 + d4, d1+d2+d3, d2+d3+d4 and d1+d2+d3+d4 are
--   all between -9 and 9, as the banana counter cannot lose or gain more
--   than 9 bananas in a row.
-- * d1+d2+d3+d4 has to be high enough, otherwise we would be forced to buy
--   zero bananas for -9, one banana for -8, etc.
-- Further, we can try the sequences with highest d1+d2+d3+d4 first,
-- as they will give the most bananas.

-- Count the number of possibilities this leaves us
function count_possible_sequences ()
  local count = 0
  for d1 = -9, 9 do
    for d2 = -9, 9 do
      for d3 = -9, 9 do
        for d4 = -9, 9 do
          if d1+d2+d3+d4 < -9 or d1+d2+d3+d4 > 9 then
            -- do nothing
          elseif d1+d2 < -9 or d1+d2 > 9
            or d2+d3 < -9 or d2+d3 > 9
            or d3+d4 < -9 or d3+d4 > 9
            or d1+d2+d3 < -9 or d1+d2+d3 > 9
            or d2+d3+d4 < -9 or d2+d3+d4 > 9 then
            -- do nothing
          else
            count = count + 1
          end
        end
      end
    end
  end
  return count
end

print("Sequences to try: ", count_possible_sequences())

-- * We can then iterate over all code sequences and try to find the maximum,
-- we can stop prematurely if the remaining codes with maximum bananas (9)
-- would not allow to equate the current maximum found.
-- * We have to precompute the prices and change sequences for the input,
--   to avoid recomputing the sequence every time.

-- Compute the price from a secret (last digit)
function secret_price (secret)
  local num = math.fmod(secret, 10)
  return math.floor(num + 0.5)
end

print("Price of secret 16495136: ", secret_price(16495136))

-- Compute the sequence of prices for a given code
function compute_prices (code)
  local prices = {}
  local secret = code
  table.insert(prices, secret_price(secret))
  for i = 1, 2000 do
    secret = next_secret(secret)
    table.insert(prices, secret_price(secret))
  end
  return prices
end

ex_prices = compute_prices(123)
print("Example 123 first ten prices:")
for i = 1, 10 do
  print(ex_prices[i])
end

-- Compute the {price, price_change} for every step
function compute_changes (code)
  local prices_changes = {}
  local secrets = compute_prices(code)
  local change = nil
  table.insert(prices_changes, {secrets[1], change})
  for i = 1, 2000 do
    local secret = secrets[1+i]
    change = secrets[1+i] - secrets[i]
    table.insert(prices_changes, {secret, change})
  end
  return prices_changes
end

ex_prices_changes = compute_changes(123)
print("Example prices and changes for the first 10 secrets 123:")
for i = 1, 10 do
  print(table.concat(ex_prices_changes[i], ', '))
end

-- Condition for a sequence of 4 changes to make sense
function changes_seq_valid (d1, d2, d3, d4)
  if d1+d2+d3+d4 < -9 or d1+d2+d3+d4 > 9 then
    return false
  elseif d1+d2 < -9 or d1+d2 > 9
    or d2+d3 < -9 or d2+d3 > 9
    or d3+d4 < -9 or d3+d4 > 9
    or d1+d2+d3 < -9 or d1+d2+d3 > 9
    or d2+d3+d4 < -9 or d2+d3+d4 > 9 then
    return false
  else
    return true
  end
end

-- Store every sequence of 4 changes which make sense
function changes_seqs ()
  local changes = {}
  for d1 = -9, 9 do
    for d2 = -9, 9 do
      for d3 = -9, 9 do
        for d4 = -9, 9 do
          if changes_seq_valid(d1,d2,d3,d4) then
            table.insert(changes, {d1, d2, d3, d4})
          end
        end
      end
    end
  end
  return changes
end

changes_to_check = changes_seqs()
print("Change sequences to check: ", #changes_to_check)

-- How many bananas do we get for a given change sequence and a given sequence
-- of price changes?
-- We stop as soon as we see the change sequence
function count_bananas (prices_changes, change_seq)
  local d1 = change_seq[1]
  local d2 = change_seq[2]
  local d3 = change_seq[3]
  local d4 = change_seq[4]
  for i = 5, #prices_changes do
    local d1c = prices_changes[i-3][2]
    if d1c == d1 then
      local d2c = prices_changes[i-2][2]
      if d2c == d2 then
        local d3c = prices_changes[i-1][2]
        if d3c == d3 then
          local d4c = prices_changes[i][2]
          if d4c == d4 then
            return prices_changes[i][1]
          end
        end
      end
    end
  end
  return 0
end

ex_bananas = count_bananas(ex_prices_changes, {-1, -1, 0, 2})
print("Example won bananas on 123: ", ex_bananas)

-- Precompute prices_changes for all codes
function prices_changes_all (codes)
  local all_prices_changes = {}
  for _, code in ipairs(codes) do
    table.insert(all_prices_changes, compute_changes(code))
  end
  return all_prices_changes
end

input_prices_changes = prices_changes_all(input_codes)

-- For a given change sequence, how many bananas in total do we get
-- across all codes?
function bananas_for_seq (all_prices_changes, change_seq)
  local bananas = 0
  for _, prices_changes in ipairs(all_prices_changes) do
    local count = count_bananas(prices_changes, change_seq)
    bananas = bananas + count
    --print("Won bananas for code ", prices_changes[1][1], ": ", count)
  end
  return bananas
end

ex_all_prices_changes = prices_changes_all({1, 2, 3, 2024})
ex_bananas = bananas_for_seq(ex_all_prices_changes, {-2, 1, -1, 3})
print("Example 1, 2, 3, 2024 number of won bananas: ", ex_bananas)

-- Find the best sequence by trying everything
function find_best_change_seq (codes)
  local changes_to_check = changes_seqs()
  local all_prices_changes = prices_changes_all(codes)
  local max_bananas = 0
  local i_seq = 0
  for _, change_seq in ipairs(changes_to_check) do
    local bananas = bananas_for_seq(all_prices_changes, change_seq)
    max_bananas = math.max(max_bananas, bananas)
    i_seq = i_seq + 1
    print("Checked sequence number ", i_seq)
  end
  return max_bananas
end

ex_max_bananas = find_best_change_seq({1,2,3,2024})
print("Best sequence for the example gathers max bananas: ", ex_max_bananas)
input_max_bananas = find_best_change_seq(input_codes) -- Takes 40min
print("Part 2 result: ", input_max_bananas) -- 1710 found?
