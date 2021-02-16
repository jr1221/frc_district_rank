class DistrictCap {
  int capacity;

  DistrictCap(String districtKey) {
    districtKey ??= '2019ne';
    switch (districtKey) {
      case '2019chs':
        capacity = 58;
        return;
      case '2019fim':
        capacity = 160;
        return;
      case '2019fma':
        capacity = 60;
        return;
      case '2019fnc':
        capacity = 32;
        return;
      case '2019in':
        capacity = 32;
        return;
      case '2019isr':
        capacity = 45;
        return;
      case '2019ne':
        capacity = 64;
        return;
      case '2019ont':
        capacity = 80;
        return;
      case '2019pch':
        capacity = 45;
        return;
      case '2019pnw':
        capacity = 64;
        return;
      case '2019tx':
        capacity = 64;
        return;
    }
  }

  String prettyCapacity() {
    return "Capacity: $capacity";
  }
}
