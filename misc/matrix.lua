-- Writen by Attractive Chaos; distributed under the MIT license

matrix = {}

function matrix.T(a)
	local m, n, x = #a, #a[1], {};
	for i = 1, n do
		x[i] = {};
		for j = 1, m do x[i][j] = a[j][i] end
	end
	return x;
end

function matrix.mul(a, b)
	assert(#a[1] == #b);
	local m, n, p, x = #a, #a[1], #b[1], {};
	local c = matrix.T(b); -- transpose for efficiency
	for i = 1, m do
		x[i] = {}
		local xi = x[i];
		for j = 1, p do
			local sum, ai, cj = 0, a[i], c[j];
			-- for luajit, caching c[j] or not makes no difference; lua is not so clever
			for k = 1, n do sum = sum + ai[k] * cj[k] end
			xi[j] = sum;
		end
	end
	return x;
end

function matgen(n)
	local a, tmp = {}, 1. / n / n;
	for i = 1, n do
		a[i] = {}
		for j = 1, n do
			a[i][j] = tmp * (i - j) * (i + j - 2) 
		end
	end
	return a;
end

function print_matrix(T)	
	local elem_str = ""
	for i = 1, #T do
        for j = 1, #T[1] do
            elem_str = elem_str .. tostring(T[i][j]) .. " "
        end
        elem_str = elem_str .. '\n'
	end
	print(elem_str)
end

local n = 800
local a, b = matgen(n), matgen(n)
t0 = os.clock()
local c = matrix.mul(a, b);
t1 = os.clock()

print(c[1][1]);
print("This took ".. tostring(t1-t0) .."s")
