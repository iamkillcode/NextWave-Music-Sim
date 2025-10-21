const { mergeSongs, calculateRegionalFanbaseGrowth } = require('../index');

describe('mergeSongs', () => {
  test('preserves server-managed fields when client omits them', () => {
    const existing = [
      { id: 's1', title: 'A', streams: 100, lastDayStreams: 10, last7DaysStreams: 50 },
    ];

    const incoming = [
      { id: 's1', title: 'A (edited)', streams: 0 },
    ];

    const merged = mergeSongs(incoming, existing, 'stat_update');

    expect(merged.length).toBe(1);
    expect(merged[0].id).toBe('s1');
    expect(merged[0].title).toBe('A (edited)');
    // Server-managed fields preserved
    expect(merged[0].streams).toBe(100);
    expect(merged[0].lastDayStreams).toBe(10);
    expect(merged[0].last7DaysStreams).toBe(50);
  });

  test('admin update overwrites server-managed fields', () => {
    const existing = [
      { id: 's1', title: 'A', streams: 100, lastDayStreams: 10, last7DaysStreams: 50 },
    ];

    const incoming = [
      { id: 's1', title: 'A (admin)', streams: 200, lastDayStreams: 5, last7DaysStreams: 20 },
    ];

    const merged = mergeSongs(incoming, existing, 'admin_stat_update');

    expect(merged.length).toBe(1);
    expect(merged[0].streams).toBe(200);
    expect(merged[0].lastDayStreams).toBe(5);
    expect(merged[0].last7DaysStreams).toBe(20);
  });

  test('handles missing id gracefully', () => {
    const existing = [
      { id: 's1', title: 'A', streams: 100 },
    ];

    const incoming = [
      { title: 'No ID', streams: 10 },
    ];

    const merged = mergeSongs(incoming, existing, 'stat_update');
    expect(merged.length).toBe(1);
    expect(merged[0].title).toBe('No ID');
  });
});

describe('calculateRegionalFanbaseGrowth', () => {
  test('converts streams to fans with home region double growth', () => {
    const currentFanbase = { usa: 100, europe: 50 };
    const songs = [
      { state: 'released', regionalStreams: { usa: 2000, europe: 1000 } },
    ];

    const result = calculateRegionalFanbaseGrowth(currentFanbase, songs, 'usa', 0);

    // 2000 streams in USA -> baseGrowth=2, home region double -> +4
    expect(result.usa).toBeGreaterThanOrEqual(104);
    // 1000 streams in Europe -> +1
    expect(result.europe).toBeGreaterThanOrEqual(51);
  });

  test('applies fame conversion bonus', () => {
    const currentFanbase = { usa: 100 };
    const songs = [
      { state: 'released', regionalStreams: { usa: 5000 } },
    ];

    const resultLowFame = calculateRegionalFanbaseGrowth(currentFanbase, songs, 'usa', 5);
    const resultHighFame = calculateRegionalFanbaseGrowth(currentFanbase, songs, 'usa', 200);

    expect(resultHighFame.usa).toBeGreaterThan(resultLowFame.usa);
  });
});
