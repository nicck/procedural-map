class Noise
  private GRAD3 = [
    [1, 1, 0], [-1, 1, 0], [1, -1, 0], [-1, -1, 0],
    [1, 0, 1], [-1, 0, 1], [1, 0, -1], [-1, 0, -1],
    [0, 1, 1], [0, -1, 1], [0, 1, -1], [0, -1, -1],
  ]

  @perm : Array(Int32) = ((1..255).to_a.shuffle) * 2

  private getter perm

  def octave_noise_2d(octaves, persistence, scale, x, y)
    total = 0.0
    frequency = scale
    amplitude = 1.0

    maxAmplitude = 0.0

    octaves.times do
      total += raw_noise_2d(x * frequency, y * frequency) * amplitude
      frequency *= 2.0
      maxAmplitude += amplitude
      amplitude *= persistence
    end

    total / maxAmplitude
  end

  def scaled_octave_noise_2d(octaves, persistence, scale, loBound, hiBound, x, y)
    (octave_noise_2d(octaves, persistence, scale, x, y) *
      (hiBound - loBound) / 2 +
      (hiBound + loBound) / 2)
  end

  def scaled_raw_noise_2d(loBound, hiBound, x, y)
    (raw_noise_2d(x, y) *
      (hiBound - loBound) / 2 +
      (hiBound + loBound) / 2)
  end

  def raw_noise_2d(x, y)
    # Noise contributions from the three corners
    n0, n1, n2 = 0.0, 0.0, 0.0

    # Skew the input space to determine which simplex cell we're in
    f2 = 0.5 * (Math.sqrt(3.0) - 1.0)
    # Hairy skew factor for 2D
    s = (x + y) * f2
    i = (x + s).to_i
    j = (y + s).to_i

    g2 = (3.0 - Math.sqrt(3.0)) / 6.0
    t = (i + j).to_f * g2
    # Unskew the cell origin back to (x,y) space
    x0 = i - t
    y0 = j - t
    # The x,y distances from the cell origin
    x0 = x - x0
    y0 = y - y0

    # For the 2D case, the simplex shape is an equilateral triangle.
    # Determine which simplex we are in.
    i1, j1 = 0, 0 # Offsets for second (middle) corner of simplex in (i,j) coords
    if x0 > y0    # lower triangle, XY order: (0,0)->(1,0)->(1,1)
      i1 = 1
      j1 = 0
    else # upper triangle, YX order: (0,0)->(0,1)->(1,1)
      i1 = 0
      j1 = 1
    end

    # A step of (1,0) in (i,j) means a step of (1-c,-c) in (x,y), and
    # a step of (0,1) in (i,j) means a step of (-c,1-c) in (x,y), where
    # c = (3-sqrt(3))/6
    x1 = x0 - i1 + g2 # Offsets for middle corner in (x,y) unskewed coords
    y1 = y0 - j1 + g2
    x2 = x0 - 1.0 + 2.0 * g2 # Offsets for last corner in (x,y) unskewed coords
    y2 = y0 - 1.0 + 2.0 * g2

    # Work out the hashed gradient indices of the three simplex corners
    ii = i.to_i & 255
    jj = j.to_i & 255

    gi0 = perm[ii + perm[jj] & 255] % 12
    gi1 = perm[ii + i1 + perm[jj + j1] & 255] % 12
    gi2 = perm[ii + 1 + perm[jj + 1] & 255] % 12

    # Calculate the contribution from the three corners
    t0 = 0.5 - x0*x0 - y0*y0
    if t0 < 0
      n0 = 0.0
    else
      t0 *= t0
      n0 = t0 * t0 * dot2d(GRAD3[gi0], x0, y0)
    end

    t1 = 0.5 - x1*x1 - y1*y1
    if t1 < 0
      n1 = 0.0
    else
      t1 *= t1
      n1 = t1 * t1 * dot2d(GRAD3[gi1], x1, y1)
    end

    t2 = 0.5 - x2*x2 - y2*y2
    if t2 < 0
      n2 = 0.0
    else
      t2 *= t2
      n2 = t2 * t2 * dot2d(GRAD3[gi2], x2, y2)
    end

    # Add contributions from each corner to get the final noise value.
    # The result is scaled to return values in the interval [-1,1].
    70.0 * (n0 + n1 + n2)
  end

  private def dot2d(g, x, y)
    return g[0]*x + g[1]*y
  end
end
