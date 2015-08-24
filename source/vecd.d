/**
* This module implements types and functions to expand and simplify the use of
* the $(LINK2 http://dlang.org/simd.html, vector extensions) of D.
*
* $(LINK2 http://github.com/nucular/vecd, GitHub) &middot; $(LINK2 http://nucular.github.io/vecd/docs/vecd.html, Online documentation)
* Copyright: Copyright the respective autors, 2015-
* License: $(LINK2 http://opensource.org/licenses/MIT, MIT License)
* Authors: nucular and $(LINK2 https://github.com/nucular/vecd/contributors, contributors)
*/

module vecd;
public import core.simd;

import std.math;
import std.traits;

/**
* Thrown when a vector operation is not supported on the target platform.
*/
class NotSupportedError : Error
{
  @safe pure nothrow this(string msg, string file = __FILE__, size_t line = __LINE__, Throwable next = null)
  {
    super(msg, file, line, next);
  }

  @safe pure nothrow this(string msg, Throwable next, string file = __FILE__, size_t line = __LINE__)
  {
    super(msg, file, line, next);
  }
}

/**
* Provides a generic template for vector-like data types.
*
* Makes use of SIMD types if available and falls back to a static-sized array
* if not.
*
* Params:
*   T = The simple type of the elements of the vector
*   D = The number of dimensions/length of the vector
*/
struct gvec(T, uint D)
{
  mixin(
    "static if (is("~T.stringof~D.stringof~"))\n"
    ~ "  " ~ T.stringof ~ D.stringof ~ " data;\n"
    ~ "else\n"
    ~ "  " ~ T.stringof ~ "[" ~ D.stringof ~ "] data;"
  );

  /**
  * Exposes the number of dimensions of the vector.
  */
  uint dim = D;

  alias x = this[0];
  alias y = this[1];
  alias z = this[2];
  alias w = this[3];

  /**
  * Initialize all dimensions of the vector to a value.
  *
  * Params:
  *   v = The value
  */
  this(T v)
  {
    this = v;
  }
  ///
  unittest
  {
    vec!2 a = 1.5;
    assert(a[0] == 1.5 && a[1] == 1.5);
  }

  /**
  * Initialize the vector to an array of values up to either the length of the
  * array or the number of dimensions of the vector.
  *
  * Params:
  *   v = The array of values
  */
  this(T[] v)
  {
    for (size_t i; i < v.length && i < this.dim; i++)
    {
      this[i] = v[i];
    }
  }
  ///
  unittest
  {
    vec!2 a = [-1, 1];
    assert(a[0] == -1 && a[1] == 1);
    vec!2 b = [-1, 1, 2];
    assert(b.dim == 2 && b[0] == -1 && b[1] == 1);
  }

  /**
  * Initialize the vector to the contents of another vector of the same type
  * and size.
  *
  * Params:
  *   v = The vector
  */
  this(gvec!(T, D) v)
  {
    for (size_t i; i < v.dim && i < this.dim; i++)
    {
      this[i] = v[i];
    }
  }
  ///
  unittest
  {
    vec!3 a = [-1, 0, 1];
    vec!3 b = a;
    assert(a == b);
  }

  /**
  * Returns a duplicate of the vector.
  */
  gvec!(T, D) dup()
  {
    return gvec!(T, D)(this);
  }
  ///
  unittest
  {
    vec!2 a = [0, 0];
    vec!2 b = a.dup;
    a[0] = 1;
    b[1] = 2;
    assert(
      a[0] == 1 && a[1] == 0 &&
      b[0] == 0 && b[1] == 2
    );
  }

  /**
  * Implements all unary operators on a vector.
  *
  * Params:
  *   op = The operator
  */
  gvec!(T, D) opUnary(string op)()
  {
    mixin(
      "static if (__traits(compiles, " ~ op ~ "data))\n"
      ~ "{\n"
      ~ "  return " ~ op ~ "data;\n"
      ~ "}\n"
      ~ "else static if (__traits(compiles, " ~ op ~ "data[]))\n"
      ~ "{\n"
      ~ "  T[D] tmp = " ~ op ~ "data[];\n"
      ~ "  return gvec!(T, D)(tmp);\n"
      ~ "}\n"
      ~ "else static if (__traits(compiles, " ~ op ~ "data.array[]))\n"
      ~ "{\n"
      ~ "  T[D] tmp = " ~ op ~ "data.array[];\n"
      ~ "  return gvec!(T, D)(tmp);\n"
      ~ "}\n"
      ~ "else\n"
      ~ "{\n"
      ~ "  throw new NotSupportedError(\"Unary \" ~ op ~ \" operator\");\n"
      ~ "}"
    );
  }
  ///
  unittest
  {
    vec!3 a = [-1f, 0f, 1f];
    assert(-a == vec!3([1f, -0f, -1f]));
  }

  /**
  * Implements all binary operators on two vectors of the same length and type.
  *
  * Params:
  *   op = The operator
  *   that = The second vector
  */
  gvec!(T, D) opBinary(string op)(gvec!(T, D) that)
  {
    mixin(
      "static if (__traits(compiles, data " ~ op ~ " that.data))\n"
      ~ "{\n"
      ~ "  return gvec!(T, D)(data " ~ op ~ " that.data);\n"
      ~ "}\n"
      ~ "else static if (__traits(compiles, data[] " ~ op ~ " that.data[]))\n"
      ~ "{\n"
      ~ "  T[D] tmp = data[] " ~ op ~ " that.data[];\n"
      ~ "  return gvec!(T, D)(tmp);\n"
      ~ "}\n"
      ~ "else static if (__traits(compiles, data.array[] " ~ op ~ " that.data.array[]))\n"
      ~ "{\n"
      ~ "  T[D] tmp = data.array[] " ~ op ~ " that.data.array[];\n"
      ~ "  return gvec!(T, D)(tmp);\n"
      ~ "}\n"
      ~ "else\n"
      ~ "{\n"
      ~ "  throw new NotSupportedError(\"Binary \" ~ op ~ \" operator\");\n"
      ~ "}"
    );
  }
  ///
  unittest
  {
    vec!2 a = [1, 2];
    vec!2 b = [3, 4];
    assert(a + b == vec!2([4, 6]));
    assert(a - b == vec!2([-2, -2]));
    assert(a * b == vec!2([3, 8]));
    assert(b / a == vec!2([3, 2]));
  }

  /**
  * Implements all binary operators with a value of the type of the vector or a
  * type that can be casted to it implicitely.
  *
  * Params:
  *   op = The operator
  *   that = The second vector
  */
  gvec!(T, D) opBinary(string op)(T that)
  {
    mixin(
      "static if (__traits(compiles, data " ~ op ~ " that))\n"
      ~ "{\n"
      ~ "  return gvec!(T, D)(data " ~ op ~ " that);\n"
      ~ "}\n"
      ~ "else static if (__traits(compiles, data[] " ~ op ~ " that))\n"
      ~ "{\n"
      ~ "  T[D] tmp = data[] " ~ op ~ " that;\n"
      ~ "  return gvec!(T, D)(tmp);\n"
      ~ "}\n"
      ~ "else static if (__traits(compiles, data.array[] " ~ op ~ " that))\n"
      ~ "{\n"
      ~ "  T[D] tmp = data.array[] " ~ op ~ " that;\n"
      ~ "  return gvec!(T, D)(tmp);\n"
      ~ "}\n"
      ~ "else\n"
      ~ "{\n"
      ~ "  throw new NotSupportedError(\"Binary \" ~ op ~ \" operator\");\n"
      ~ "}"
    );
  }
  ///
  unittest
  {
    vec!2 a = [1, 2];
    assert(a + 2 == vec!2([3, 4]));
    assert(a - 2 == vec!2([-1, 0]));
    assert(a * 2 == vec!2([2, 4]));
    assert(a / 2 == vec!2([0.5, 1]));
  }

  /**
  * Implements all op assignment operators on two vectors of the same length
  * and type.
  *
  * Params:
  *   op = The operator
  *   that = The second vector
  */
  gvec!(T, D) opOpAssign(string op)(gvec!(T, D) that)
  {
    mixin(
      "static if (__traits(compiles, data " ~ op ~ " that.data))\n"
      ~ "{\n"
      ~ "  data = data " ~ op ~ " that.data;"
      ~ "}\n"
      ~ "else static if (__traits(compiles, data[] " ~ op ~ " that.data[]))\n"
      ~ "{\n"
      ~ "  T[D] tmp = data[] " ~ op ~ " that.data[];\n"
      ~ "  data = tmp;\n"
      ~ "}\n"
      ~ "else static if (__traits(compiles, data.array[] " ~ op ~ " that.data.array[]))\n"
      ~ "{\n"
      ~ "  T[D] tmp = data.array[] " ~ op ~ " that.data.array[];\n"
      ~ "  data.array = tmp;\n"
      ~ "}\n"
      ~ "else\n"
      ~ "{\n"
      ~ "  throw new NotSupportedError(\"Binary \" ~ op ~ \" operator\");\n"
      ~ "}"
    );
    return this;
  }
  unittest
  {
    vec!4 a = [0, 1, 2, 3];
    a *= a;
    assert(a == vec!4([0, 1, 4, 9]));
  }

  /**
  * Implements all op assignment operators with a value of the type of the
  * vector or a type that can be casted to it implicitely.
  *
  * Params:
  *   op = The operator
  *   that = The value
  */
  gvec!(T, D) opOpAssign(string op)(T that)
  {
    mixin(
      "static if (__traits(compiles, data " ~ op ~ " that))\n"
      ~ "{\n"
      ~ "  data = data " ~ op ~ " that;"
      ~ "}\n"
      ~ "else static if (__traits(compiles, data[] " ~ op ~ " that))\n"
      ~ "{\n"
      ~ "  T[D] tmp = data[] " ~ op ~ " that;\n"
      ~ "  data = tmp;\n"
      ~ "}\n"
      ~ "else static if (__traits(compiles, data.array[] " ~ op ~ " that))\n"
      ~ "{\n"
      ~ "  T[D] tmp = data.array[] " ~ op ~ " that;\n"
      ~ "  data.array = tmp;\n"
      ~ "}\n"
      ~ "else\n"
      ~ "{\n"
      ~ "  throw new NotSupportedError(\"Binary \" ~ op ~ \" operator\");\n"
      ~ "}"
    );
    return this;
  }
  unittest
  {
    vec!4 a = [0, 1, 2, 3];
    a *= 2;
    assert(a == vec!4([0, 2, 4, 6]));
  }

  /**
  * Implements the assignment operator with a value of the type of the
  * vector or a type that can be casted to it implicitely.
  *
  * Params:
  *   v = The value all dimensions will be set to
  */
  void opAssign(T v)
  {
    for (size_t i = 0; i < dim; i++)
      this[i] = v;
  }
  ///
  unittest
  {
    vec!2 a;
    a = 1;
    assert(a[0] == 1 && a[1] == 1);
  }

  /**
  * Implements the assignment operator with an array of the type of the
  * vector or a type that can be casted to it implicitely.
  *
  * Params:
  *   v = The value all dimensions will be set to
  */
  void opAssign(T[] v)
  {
    for (size_t i = 0; i < v.length && i < dim; i++)
      this[i] = v[i];
  }
  ///
  unittest
  {
    vec!2 a;
    a = [1, 2, 3];
    assert(a[0] == 1 && a[1] == 2);
  }

  /**
  * Implements the index operator.
  *
  * Params:
  *   i = The index
  */
  T opIndex(size_t i)
  {
    static if (__traits(compiles, data[i]))
      return data[i];
    else static if (__traits(compiles, data.array[i]))
      return data.array[i];
    else
      throw new NotSupportedError("Index operator");
  }
  ///
  unittest
  {
    vec!3 a = [2, 1, 0];
    assert(a[0] == 2);
    assert(a[1] == 1);
    assert(a[2] == 0);
  }

  /**
  * Implements the index assignment operator.
  *
  * Params:
  *   v = The value
  *   i = The index the value is assigned to
  */
  T opIndexAssign(T v, size_t i)
  {
    static if (__traits(compiles, data[i]))
      return data[i] = v;
    else static if (__traits(compiles, data.array[i]))
      return data.array[i] = v;
    else
      throw new NotSupportedError("Index assignment operator");
  }
  ///
  unittest
  {
    vec!3 a;
    a[0] = 2;
    a[1] = 1;
    a[2] = 0;
    assert(a[0] == 2);
    assert(a[1] == 1);
    assert(a[2] == 0);
  }

  /**
  * Implements all index op assignment operators.
  *
  * Params:
  *   c = The rvalue of the assignment
  *   i = The index the rvalue is op-assigned to
  */
  T opIndexOpAssign(string op)(T c, size_t i)
  {
    mixin("return this[i] = this[i] " ~ op ~ " c;");
  }
  ///
  unittest
  {
    vec!2 a = [-1, 1];
    a[0] += 2;
    assert(a[0] == 1);
  }

  /**
  * Implements the dollar operator.
  **/
  uint opDollar()
  {
    return D;
  }
  ///
  unittest
  {
    vec!3 a = [3, 2, 1];
    assert(a[$-1] == 1);
    assert(a[$-2] == 2);
    assert(a[$-3] == 3);
  }

  /*
  * Implements a conversion from vector to string.
  */
  string toString()
  {
    import std.conv;
    return to!string(data);
  }
  ///
  unittest
  {
    vec!4 a = [1, 3, 3, 7];
    assert(a.toString() == "[1, 3, 3, 7]");
  }

  /**
  * Normalizes the vector in-place.
  */
  void normalize()
  {
    this /= this.length();
  }

  /**
  * Returns a normalized copy of the vector.
  */
  gvec!(T, D) normalized()
  {
    return this.dup / this.length();
  }

  /**
  * Returns the length/magnitude of the vector.
  */
  double length()
  {
    double l = 0.0f;
    for (size_t i = 0; i < dim; i++)
      l += this[i]^^2;
    return sqrt(l);
  }

  /**
  * Returns the squared length/magnitude of the vector.
  */
  double length2()
  {
    double l = 0.0f;
    for (size_t i = 0; i < dim; i++)
      l += this[i]^^2;
    return l;
  }
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
