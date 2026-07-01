/**
 * 地理位置工具函数
 * 集中管理 Haversine 距离计算、方位角、目标点推算等地理算法，
 * 消除项目中三处重复实现。
 *
 * 使用方法:
 *   import { haversineDistance, calculateBearing, destinationPoint, toRadians, toDegrees } from '../utils/GeoUtils';
 *   const d: number = haversineDistance({ latitude: 39.9, longitude: 116.4 }, { latitude: 40.0, longitude: 116.5 });
 */

/** 地球平均半径 (米) */
const EARTH_RADIUS_METERS: number = 6371000;

/** 地理位置坐标点 */
export interface GeoPoint {
  latitude: number;
  longitude: number;
}

/**
 * 角度转弧度
 */
export function toRadians(degrees: number): number {
  return degrees * Math.PI / 180;
}

/**
 * 弧度转角度
 */
export function toDegrees(radians: number): number {
  return radians * 180 / Math.PI;
}

/**
 * Haversine 公式：计算两点间的地面距离 (米)
 * @returns 四舍五入到整数的米制距离
 */
export function haversineDistance(from: GeoPoint, to: GeoPoint): number {
  const latitudeDelta: number = toRadians(to.latitude - from.latitude);
  const longitudeDelta: number = toRadians(to.longitude - from.longitude);
  const fromLatitude: number = toRadians(from.latitude);
  const toLatitude: number = toRadians(to.latitude);

  const haversine: number =
    Math.sin(latitudeDelta / 2) * Math.sin(latitudeDelta / 2) +
    Math.cos(fromLatitude) * Math.cos(toLatitude) *
    Math.sin(longitudeDelta / 2) * Math.sin(longitudeDelta / 2);

  const angularDistance: number = 2 * Math.atan2(Math.sqrt(haversine), Math.sqrt(1 - haversine));

  return Math.round(EARTH_RADIUS_METERS * angularDistance);
}

/**
 * 计算从 from 到 to 的方位角 (度)，正北为 0°
 * @returns 方位角 (0-360)
 */
export function calculateBearing(from: GeoPoint, to: GeoPoint): number {
  const fromLat: number = toRadians(from.latitude);
  const toLat: number = toRadians(to.latitude);
  const deltaLng: number = toRadians(to.longitude - from.longitude);

  const y: number = Math.sin(deltaLng) * Math.cos(toLat);
  const x: number = Math.cos(fromLat) * Math.sin(toLat) -
    Math.sin(fromLat) * Math.cos(toLat) * Math.cos(deltaLng);

  const bearingRad: number = Math.atan2(y, x);
  return toDegrees(bearingRad);
}

/**
 * 从起点出发，沿指定方向和距离推算目标点
 * @param from    起点坐标
 * @param distanceMeters  距离 (米)
 * @param bearingDegrees  方位角 (度)
 * @returns 目标点坐标
 */
export function destinationPoint(from: GeoPoint, distanceMeters: number, bearingDegrees: number): GeoPoint {
  const angularDistance: number = distanceMeters / EARTH_RADIUS_METERS;
  const bearingRad: number = toRadians(bearingDegrees);
  const fromLat: number = toRadians(from.latitude);
  const fromLng: number = toRadians(from.longitude);

  const toLat: number = Math.asin(
    Math.sin(fromLat) * Math.cos(angularDistance) +
    Math.cos(fromLat) * Math.sin(angularDistance) * Math.cos(bearingRad)
  );

  const toLng: number = fromLng + Math.atan2(
    Math.sin(bearingRad) * Math.sin(angularDistance) * Math.cos(fromLat),
    Math.cos(angularDistance) - Math.sin(fromLat) * Math.sin(toLat)
  );

  return {
    latitude: toDegrees(toLat),
    longitude: toDegrees(toLng)
  };
}
