-- Picotron-compatible Quicksort Library
-- by @Felice from https://www.lexaloffle.com/bbs/?pid=50453
local function ascending(a, b) return a < b end

local function qsort(array, comparator, left, right)
    comparator, left, right = comparator or ascending, left or 1, right or #array
    if left < right then
        if comparator(array[right], array[left]) then
            array[left], array[right] = array[right], array[left]
        end
        local less_than, greater_than, current, pivot_low, pivot_high = left + 1, right - 1, left + 1, array[left],
           array[right]
        while current <= greater_than do
            if comparator(array[current], pivot_low) then
                array[current], array[less_than] = array[less_than], array[current]
                less_than += 1
            elseif not comparator(array[current], pivot_high) then
                while comparator(pivot_high, array[greater_than]) and current < greater_than do
                    greater_than -= 1
                end
                array[current], array[greater_than] = array[greater_than], array[current]
                greater_than -= 1
                if comparator(array[current], pivot_low) then
                    array[current], array[less_than] = array[less_than], array[current]
                    less_than += 1
                end
            end
            current += 1
        end
        less_than -= 1
        greater_than += 1
        array[left], array[less_than] = array[less_than], array[left]
        array[right], array[greater_than] = array[greater_than], array[right]
        qsort(array, comparator, left, less_than - 1)
        qsort(array, comparator, less_than + 1, greater_than - 1)
        qsort(array, comparator, greater_than + 1, right)
    end
end

return qsort
