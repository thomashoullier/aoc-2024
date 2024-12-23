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
