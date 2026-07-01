import { GeoPoint } from '../../models/Location';

export interface LocationPreset {
  id: string;
  label: string;
  description: string;
  location: GeoPoint;
}

// M5 will replace this temporary center point with the device location.
export const DEFAULT_MOCK_LOCATION: GeoPoint = {
  latitude: 31.2304,
  longitude: 121.4737
};

export const MANUAL_LOCATION_PRESETS: LocationPreset[] = [
  {
    id: 'downtown',
    label: '市中心',
    description: '午休附近',
    location: DEFAULT_MOCK_LOCATION
  },
  {
    id: 'campus',
    label: '学校附近',
    description: '学生食堂圈',
    location: {
      latitude: 31.2248,
      longitude: 121.4668
    }
  },
  {
    id: 'community',
    label: '社区附近',
    description: '下班回家路上',
    location: {
      latitude: 31.2386,
      longitude: 121.4822
    }
  }
];

