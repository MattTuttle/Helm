import SemVer;

class TestSemVer extends haxe.unit.TestCase
{

	public function testValues()
	{
		var a:SemVer = "0.9.43-rc.6",
			b:SemVer = "0.9.43-rc.6";

		assertEquals(a.major, b.major);
		assertEquals(0, a.major);

		assertEquals(a.minor, b.minor);
		assertEquals(9, a.minor);

		assertEquals(a.patch, b.patch);
		assertEquals(43, a.patch);

		assertEquals(a.preRelease, b.preRelease);
		assertEquals(PreRelease.ReleaseCandidate, a.preRelease);

		assertEquals(a.preReleaseNum, b.preReleaseNum);
		assertEquals(6, a.preReleaseNum);
	}

	public function testComparison()
	{
		var a:SemVer = "1.1.0",
			b:SemVer = "1.1.3",
			c:SemVer = "1.1.0-alpha.1",
			d:SemVer = "1.1.0-beta",
			e:SemVer = "1.1.0-alpha.2",
			f:SemVer = "0.2.5",
			g:SemVer = "4.7.2",
			h:SemVer = "1.1.0-alpha.2";

		assertTrue(a < b);
		assertTrue(a <= b);
		assertTrue(a > c);
		assertTrue(a == a);
		assertTrue(a != c);
		assertFalse(b == c);
		assertTrue(d > c);
		assertTrue(c < d);
		assertTrue(c <= d);
		assertTrue(a >= d);
		assertTrue(e > c);
		assertFalse(c >= e);
		assertTrue(c < e);
		assertFalse(e <= c);
		assertTrue(f < a);
		assertFalse(f > c);
		assertTrue(g > f);
		assertFalse(a > g);
		assertFalse(g < c);
		assertTrue(f <= g);
		assertTrue(e == h);
		assertFalse(e != h);
		assertTrue(e != c);
	}

	public function testNull()
	{
		var a:SemVer = "1.1.0",
			b:SemVer = null;

		assertFalse(a == null);
		assertFalse(null == a);
		assertTrue(b == null);
		assertTrue(null == b);
	}

	public function testToString()
	{
		var a:SemVer = "1.0.0-alpha.1";
		assertEquals("1.0.0-alpha.1", a.toString());
	}

}
