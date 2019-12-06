import helm.ds.SemVer;
import utest.Test;
import utest.Assert;

class TestSemVer extends Test {
	public function testValues() {
		var a:SemVer = "0.9.43-rc.6", b:SemVer = "0.9.43-rc.6";

		Assert.equals(a.major, b.major);
		Assert.equals(0, a.major);

		Assert.equals(a.minor, b.minor);
		Assert.equals(9, a.minor);

		Assert.equals(a.patch, b.patch);
		Assert.equals(43, a.patch);

		Assert.equals(a.preRelease, b.preRelease);
		Assert.equals(PreRelease.ReleaseCandidate, a.preRelease);

		Assert.equals(a.preReleaseNum, b.preReleaseNum);
		Assert.equals(6, a.preReleaseNum);
	}

	public function testComparison() {
		var a:SemVer = "1.1.0",
			b:SemVer = "1.1.3",
			c:SemVer = "1.1.0-alpha.1",
			d:SemVer = "1.1.0-beta",
			e:SemVer = "1.1.0-alpha.2",
			f:SemVer = "0.2.5",
			g:SemVer = "4.7.2",
			h:SemVer = "1.1.0-alpha.2";

		Assert.isTrue(a < b);
		Assert.isTrue(a <= b);
		Assert.isTrue(a > c);
		Assert.isTrue(a == a);
		Assert.isTrue(a != c);
		Assert.isFalse(b == c);
		Assert.isTrue(d > c);
		Assert.isTrue(c < d);
		Assert.isTrue(c <= d);
		Assert.isTrue(a >= d);
		Assert.isTrue(e > c);
		Assert.isFalse(c >= e);
		Assert.isTrue(c < e);
		Assert.isFalse(e <= c);
		Assert.isTrue(f < a);
		Assert.isFalse(f > c);
		Assert.isTrue(g > f);
		Assert.isFalse(a > g);
		Assert.isFalse(g < c);
		Assert.isTrue(f <= g);
		Assert.isTrue(e == h);
		Assert.isFalse(e != h);
		Assert.isTrue(e != c);
	}

	public function testNull() {
		var a:SemVer = "1.1.0", b:SemVer = null;

		Assert.isFalse(a == null);
		Assert.isFalse(null == a);
		Assert.isTrue(b == null);
		Assert.isTrue(null == b);
	}

	public function testToString() {
		var a:SemVer = "1.0.0-alpha.1";
		Assert.equals("1.0.0-alpha.1", a.toString());
	}
}
