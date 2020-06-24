# Tic4
A simple 4x4 Tic Tac Toe playing AI in Lua and Lobster. In addition to four in a row (or column or diagonal), four in a square also win. Other than playing with [Lobster](http://aardappel.github.io/lobster/README_FIRST.html) as a language that was new to me but which I quite liked, I also wanted to benchmark both languages using constructs that are as equivalent as possible. The <em>negamax</em> modules contain a generic negamax implementation and the <em>tic4</em> files implement the specific rules for this 4x4 TTT variant.

Winning conditions:
<p>
o&ensp;.&ensp;.&ensp;.&emsp;&emsp; .&ensp;.&ensp;.&ensp;.<br>
.&ensp;o&ensp;.&ensp;.&emsp;&emsp; .&ensp;o&ensp;o&ensp;.<br>
.&ensp;.&ensp;o&ensp;.&emsp;&emsp; .&ensp;o&ensp;o&ensp;.<br>
.&ensp;.&ensp;.&ensp;o&emsp;&emsp; .&ensp;.&ensp;.&ensp;.<br>
</p>

#### Playing against it
You can run it to play (both the tic4 and negamax files are needed in each language) but you have to live with a very simple command line interface for now.<br>
```
lua/luajit tic4.lua
lobster tic4.lobster
```

#### Benchmark mode
One can also run it to *benchmark* the languages and implementations by calling<br>
```
lua/luajit tic4.lua bench
lobster tic4.lobster -- bench
```

#### Benchmark results
<p>
These are the results for my machine (i5-4690K @3.5GHz) using the latest Lobster (x64 Release using VS2019), Lua 5.1.4, and the HEAD version of Luajit 2.1-beta3. While the Lobster VM is currently only slightly faster than Lua 5.1.4, the version compiled to C++ (using the --cpp switch) even beats Luajit 2.1 quite comfortably which I thought was a remarkable result.

![Benchmark results](bench_results.png)
</p>
