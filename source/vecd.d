/**
* This module implements types and functions to expand and simplify the use of
* the $(LINK2 http://dlang.org/simd.html, vector extensions) of D.
*
* Copyright: Copyright the respective autors, 2015-
* License: $(LINK2 http://opensource.org/licenses/MIT, MIT License)
* Authors: nucular and $(LINK2 https://github.com/nucular/vecd/contributors, contributors)
*/

module vecd;
public import core.simd;

import std.traits;

/**
* Provides a generic template for vector-like data types.
*
* Makes use of SIMD types if available and falls back to a static-sized array
* if not.
*
* Params:
*   T = The simple type of the elements of the vector
*   D = The number of dimensions/length of the vector
*
* Macros:
*   GVEC = A vector of `$1`s.
*/
template gvec(T, uint D)
{
  mixin(
    "static if (__traits(compiles, "~T.stringof~D.stringof~"))\n"
    ~ "  alias gvec = "~T.stringof~D.stringof~";\n"
    ~ "else\n"
    ~ "  alias gvec = "~T.stringof~"["~D.stringof~"];"
  );
}

/**
* A vector of `bool`s.
* Params:
*   D = The number of dimensions/length of the vector
*/
alias bvec(uint D) = gvec!(bool, D);
/**
* A vector of `int`s.
* Params:
*   D = The number of dimensions/length of the vector
*/
alias ivec(uint D) = gvec!(int, D);
/**
* A vector of `uint`s.
* Params:
*   D = The number of dimensions/length of the vector
*/
alias uvec(uint D) = gvec!(uint, D);
/**
* A vector of `float`s.
* Params:
*   D = The number of dimensions/length of the vector
*/
alias vec(uint D) = gvec!(float, D);
/**
* A vector of `double`s.
* Params:
*   D = The number of dimensions/length of the vector
*/
alias dvec(uint D) = gvec!(double, D);
