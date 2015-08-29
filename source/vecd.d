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

import std.format;
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
*   D = The number of components of the vector
*/
struct gvec(T, uint D)
{
  mixin(q{
    static if (is(%1$s%2$s))
    {
      %1$s%2$s data;
      enum bool simd = true;
    }
    else
    {
      %1$s[%2$s] data;
      enum bool simd = false;
    }
  }.format(T.stringof, D.stringof));

  /// Exposes the number of components of the vector.
  enum uint dim = D;

  // TODO: Find a better way of doing multi-component swizzles

  /// The X-component of the vector.
  static if (D >= 1)
  {
    @property x() { static if (simd) return data.array[0]; else return data[0]; }
    @property x(T v) { static if (simd) data.array[0] = v; else data[0] = v; }
  }
  static if (D >= 2)
  {
    /// The Y-component of the vector.
    @property y() { static if (simd) return data.array[1]; else return data[1]; }
    @property y(T v) { static if (simd) data.array[1] = v; else data[1] = v; }
    @property xy() { return gvec!(T, 2)([this[0], this[1]]); }
    @property xy(gvec!(T, 2) v) { this[0] = v[0]; this[1] = v[1]; }
    @property xy(T[2] v) { this[0] = v[0]; this[1] = v[1]; }
    @property xy(T v) { this[0] = v; this[1] = v; }
    @property yx() { return gvec!(T, 2)([this[1], this[0]]); }
    @property yx(gvec!(T, 2) v) { this[0] = v[1]; this[1] = v[0]; }
    @property yx(T[2] v) { this[0] = v[1]; this[1] = v[0]; }
    @property yx(T v) { this[0] = v; this[1] = v; }
  }
  static if (D >= 3)
  {
    /// The Z-component of the vector.
    @property z() { static if (simd) return data.array[2]; else return data[2]; }
    @property z(T v) { static if (simd) data.array[2] = v; else data[2] = v; }
    @property xz() { return gvec!(T, 2)([this[0], this[2]]); }
    @property xz(gvec!(T, 2) v) { this[0] = v[0]; this[2] = v[1]; }
    @property xz(T[2] v) { this[0] = v[0]; this[2] = v[1]; }
    @property xz(T v) { this[0] = v; this[2] = v; }
    @property yz() { return gvec!(T, 2)([this[1], this[2]]); }
    @property yz(gvec!(T, 2) v) { this[1] = v[0]; this[2] = v[1]; }
    @property yz(T[2] v) { this[1] = v[0]; this[2] = v[1]; }
    @property yz(T v) { this[1] = v; this[2] = v; }
  }
  static if (D >= 4)
  {
    /// The W-component of the vector.
    @property w() { static if (simd) return data.array[3]; else return data[3]; }
    @property w(T v) { static if (simd) data.array[3] = v; else data[3] = v; }
  }

  /**
  * Initialize all components of the vector to a value.
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
  * Initialize the vector to an array of the same type with the same length as
  * the vector.
  *
  * Params:
  *   v = The array of values
  */
  this(T[D] v)
  {
    this = v;
  }
  ///
  unittest
  {
    vec!2 a = [-1, 1];
    assert(a[0] == -1 && a[1] == 1);
  }

  /**
  * Initialize the vector to an array of values up to either the length of the
  * array or the number of components of the vector.
  *
  * Params:
  *   v = The array of values
  */
  this(T[] v)
  {
    this = v[0..D];
  }
  ///
  unittest
  {
    vec!2 a = [-1, 1, 2];
    assert(a.dim == 2 && a[0] == -1 && a[1] == 1);
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
    this = v;
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
  /// Alias for dup
  alias xyz = dup;

  /**
  * Implements all unary operators on a vector.
  *
  * Params:
  *   op = The operator
  */
  gvec!(T, D) opUnary(string op)()
  {
    mixin(q{
      static if (__traits(compiles, %1$s data))
      {
        return %1$s data;
      }
      else static if (__traits(compiles, %1$s data[]))
      {
        T[D] tmp = %1$s data[];
        return gvec!(T, D)(tmp);
      }
      else static if (__traits(compiles, %1$s data.array[]))
      {
        T[D] tmp = %1$s data.array[];
        return gvec!(T, D)(tmp);
      }
      else
      {
        throw new NotSupportedError("Unary %1$s operator");
      }
    }.format(op));
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
    mixin(q{
      static if (__traits(compiles, data %1$s that.data))
      {
        return gvec!(T, D)(data %1$s that.data);
      }
      else static if (__traits(compiles, data[] %1$s that.data[]))
      {
        T[D] tmp = data[] %1$s that.data[];
        return gvec!(T, D)(tmp);
      }
      else static if (__traits(compiles, data.array[] %1$s that.data.array[]))
      {
        T[D] tmp = data.array[] %1$s that.data.array[];
        return gvec!(T, D)(tmp);
      }
      else
      {
        throw new NotSupportedError("Binary %1$s operator");
      }
    }.format(op));
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
  * Implements all binary operators with a scalar of the type of the vector or a
  * type that can be casted to it implicitely.
  *
  * Params:
  *   op = The operator
  *   that = The scalar
  */
  gvec!(T, D) opBinary(string op)(T that)
  {
    mixin(q{
      static if (__traits(compiles, data %1$s that))
      {
        return gvec!(T, D)(data %1$s that);
      }
      else static if (__traits(compiles, data[] %1$s that))
      {
        T[D] tmp = data[] %1$s that;
        return gvec!(T, D)(tmp);
      }
      else static if (__traits(compiles, data.array[] %1$s that))
      {
        T[D] tmp = data.array[] %1$s that;
        return gvec!(T, D)(tmp);
      }
      else
      {
        throw new NotSupportedError("Binary %1$s operator");
      }
    }.format(op));
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
    mixin(q{
      static if (__traits(compiles, data %1$s that.data))
      {
        data = data %1$s that.data;
      }
      else static if (__traits(compiles, data[] %1$s that.data[]))
      {
        T[D] tmp = data[] %1$s that.data[];
        data = tmp;
      }
      else static if (__traits(compiles, data.array[] %1$s that.data.array[]))
      {
        T[D] tmp = data.array[] %1$s that.data.array[];
        data.array = tmp;
      }
      else
      {
        throw new NotSupportedError("Binary %1$s operator");
      }
    }.format(op));
    return this;
  }
  unittest
  {
    vec!4 a = [0, 1, 2, 3];
    a *= a;
    assert(a == vec!4([0, 1, 4, 9]));
  }

  /**
  * Implements all op assignment operators with a scalar of the type of the
  * vector or a type that can be casted to it implicitely.
  *
  * Params:
  *   op = The operator
  *   that = The scalar
  */
  gvec!(T, D) opOpAssign(string op)(T that)
  {
    mixin(q{
      static if (__traits(compiles, data %1$s that))
      {
        data = data %1$s that;
      }
      else static if (__traits(compiles, data[] %1$s that))
      {
        T[D] tmp = data[] %1$s that;
        data = tmp;
      }
      else static if (__traits(compiles, data.array[] %1$s that))
      {
        T[D] tmp = data.array[] %1$s that;
        data.array = tmp;
      }
      else
      {
        throw new NotSupportedError("Binary %1$s operator");
      }
    }.format(op));
    return this;
  }
  unittest
  {
    vec!4 a = [0, 1, 2, 3];
    a *= 2;
    assert(a == vec!4([0, 2, 4, 6]));
  }

  /**
  * Implements the assignment operator with a scalar of the type of the
  * vector or a type that can be casted to it implicitely.
  *
  * Params:
  *   v = The scalar
  */
  void opAssign(T v)
  {
    static if (__traits(compiles, data = v))
    {
      data = v;
    }
    else
    {
      for (uint i = 0; i < dim; i++)
        this[i] = v;
    }

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
  * vector (or a type that can be casted to it implicitely).
  *
  * Params:
  *   v = The array containing the components
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
  * Implements the assignment operator with an array of the type of the
  * vector (or a type that can be casted to it implicitely) and the same
  * number of components.
  *
  * Params:
  *   v = The array containing the components
  */
  void opAssign(T[D] v)
  {
    static if (simd)
      this.data.array = v;
    else
      this.data = v;
  }
  ///
  unittest
  {
    vec!2 a;
    a = [1, 2];
    assert(a[0] == 1 && a[1] == 2);
  }

  /**
  * Implements the apply operator for `foreach` iteration with one parameter.
  *
  * Params:
  *   dg = The delegate that is applied
  */
  int opApply(int delegate(ref T) dg)
  {
    int result = 0;
    for (uint i = 0; i < D; i++)
    {
      static if (simd)
        result = dg(data.array[i]);
      else
        result = dg(data[i]);
      if (result)
        break;      
    }
    return result;
  }
  ///
  unittest
  {
    vec!3 a = [0, 0, 0];
    foreach (float v; a)
      assert(v == 0);
  }

  /**
  * Implements the apply operator for `foreach_reverse` iteration with one
  * parameter.
  *
  * Params:
  *   dg = The delegate that is applied
  */
  int opApplyReverse(int delegate(ref T) dg)
  {
    int result = 0;
    for (int i = D-1; i >= 0; i--)
    {
      static if (simd)
        result = dg(data.array[i]);
      else
        result = dg(data[i]);
      if (result)
        break;      
    }
    return result;
  }
  ///
  unittest
  {
    vec!3 a = [0, 0, 0];
    foreach_reverse (float v; a)
      assert(v == 0);
  }

  /**
  * Implements the apply operator for `foreach` iteration with two parameters.
  *
  * Params:
  *   dg = The delegate that is applied
  */
  int opApply(int delegate(int, ref T) dg)
  {
    int result = 0;
    for (int i = 0; i < D; i++)
    {
      static if (simd)
        result = dg(i, data.array[i]);
      else
        result = dg(i, data[i]);
      if (result)
        break;      
    }
    return result;
  }
  ///
  unittest
  {
    vec!3 a = [0, 1, 2];
    foreach (int i, float v; a)
      assert(i == v);
  }

  /**
  * Implements the apply operator for `foreach_reverse` iteration with two
  * parameters.
  *
  * Params:
  *   dg = The delegate that is applied
  */
  int opApplyReverse(int delegate(int, ref T) dg)
  {
    int result = 0;
    for (int i = D-1; i >= 0; i--)
    {
      static if (simd)
        result = dg(i, data.array[i]);
      else
        result = dg(i, data[i]);
      if (result)
        break;      
    }
    return result;
  }
  ///
  unittest
  {
    vec!3 a = [0, 1, 2];
    foreach_reverse (int i, float v; a)
      assert(i == v);
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
  *   v = The scalar
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
    static if (__traits(isIntegral, T)) // pretty sure this isn't correct
      this = this / cast(T)(ceil(this.length()));
    else
      this = this / this.length();
  }
  ///
  unittest
  {
    vec!2 a = [1, 2];
    a.normalize();
  }

  /**
  * Returns a normalized copy of the vector.
  */
  gvec!(T, D) normalized()
  {
    static if (__traits(isIntegral, T)) // pretty sure this isn't correct
      return this.dup / cast(T)(ceil(this.length()));
    else
      return this.dup / cast(T)(this.length());
  }
  ///
  unittest
  {
    vec!2 a = [1, 2];
    vec!2 b = a;
    b.normalize();
    assert(a.normalized == b);
  }

  /**
  * Returns the length/magnitude of the vector.
  */
  double length()
  {
    double l = 0.0f;
    for (size_t i = 0; i < dim; i++)
      l += this[i]^^2;
    return sqrt(cast(double)l);
  }
  ///
  unittest
  {
    vec!2 a = [-1, 1];
    assert(a.length == sqrt(cast(float)2));
  }
  /// Alias for length
  alias mag = length;

  /**
  * Returns the squared length/magnitude of the vector.
  */
  T length2()
  {
    static if (__traits(isIntegral, T)) // this is bad
      int l = 0;
    else
      T l = 0;

    for (size_t i = 0; i < dim; i++)
      l += this[i]^^2;
    return cast(T)l;
  }
  ///
  unittest
  {
    vec!2 a = [-1, 1];
    assert(a.length2 == 2);
  }
  /// Alias for length2
  alias mag2 = length2;

  /**
  * Returns the dot product of two vectors.
  *
  * Params:
  *   that = Other vector
  */
  T dot(gvec!(T, D) that)
  {
    static if (__traits(isIntegral, T)) // this is bad
      int d = 0;
    else
      T d = 0;

    for (size_t i = 0; i < dim; i++)
      d += this[i] * that[i];
    return cast(T)d;
  }
  ///
  unittest
  {
    vec!3 a = [1, 3, -5];
    vec!3 b = [4, -2, -1];
    assert(a.dot(b) == 3);
  }

  /**
  * Returns the cross product of two 3D vectors.
  *
  * Params:
  *   that = Other vector
  */
  gvec!(T, D) cross(gvec!(T, D) that)
  {
    static if (D == 3)
    {
      return gvec!(T, D)([
        cast(T)(this.y * that.z - this.z * that.y),
        cast(T)(this.z * that.x - this.x * that.z),
        cast(T)(this.x * that.y - this.y * that.x)
      ]);
    }
    else
    {
      throw new NotSupportedError("Cross product");
    }
  }
}

/**
* A vector of `bool`s.
* Params:
*   D = The number of components of the vector
*/
alias bvec(uint D) = gvec!(bool, D);
/**
* A vector of `int`s.
* Params:
*   D = The number of components of the vector
*/
alias ivec(uint D) = gvec!(int, D);
/**
* A vector of `uint`s.
* Params:
*   D = The number of components of the vector
*/
alias uvec(uint D) = gvec!(uint, D);
/**
* A vector of `float`s.
* Params:
*   D = The number of components of the vector
*/
alias vec(uint D) = gvec!(float, D);
/**
* A vector of `double`s.
* Params:
*   D = The number of components of the vector
*/
alias dvec(uint D) = gvec!(double, D);

unittest
{
  bvec!1 ba; bvec!2 bb; bvec!3 bc; bvec!4 bd;
  ivec!1 ia; ivec!2 ib; ivec!3 ic; ivec!4 id;
  uvec!1 ua; uvec!2 ub; uvec!3 uc; uvec!4 ud;
  vec!1 a; vec!2 b; vec!3 c; vec!4 d;
  dvec!1 da; dvec!2 db; dvec!3 dc; dvec!4 dd;
}
