// Copyright 2009-2021 Intel Corporation
// SPDX-License-Identifier: Apache-2.0

#include "instanced_geometry_device.isph"

const uniform int numPhi = 5;
const uniform int numTheta = 2*numPhi;

RTCScene g_scene  = NULL;
uniform TutorialData data;

uniform unsigned int createTriangulatedSphere (RTCScene scene, const uniform Vec3f& p, uniform float r)
{
  /* create triangle mesh */
  RTCGeometry geom = rtcNewGeometry (g_device, RTC_GEOMETRY_TYPE_TRIANGLE);

  /* map triangle and vertex buffers */
  uniform Vertex* uniform vertices = (uniform Vertex* uniform) rtcSetNewGeometryBuffer(geom,RTC_BUFFER_TYPE_VERTEX,0,RTC_FORMAT_FLOAT3,sizeof(uniform Vertex),numTheta*(numPhi+1));
  uniform Triangle* uniform triangles = (uniform Triangle* uniform) rtcSetNewGeometryBuffer(geom,RTC_BUFFER_TYPE_INDEX,0,RTC_FORMAT_UINT3,sizeof(uniform Triangle),2*numTheta*(numPhi-1));

  /* create sphere */
  uniform int tri = 0;
  const uniform float rcpNumTheta = rcp((uniform float)numTheta);
  const uniform float rcpNumPhi   = rcp((uniform float)numPhi);
  for (uniform int phi=0; phi<=numPhi; phi++)
  {
    for (uniform int theta=0; theta<numTheta; theta++)
    {
      const uniform float phif   = phi*pi*rcpNumPhi;
      const uniform float thetaf = theta*2.0f*pi*rcpNumTheta;

      uniform Vertex& v = vertices[phi*numTheta+theta];
      v.x = p.x + r*sin(phif)*sin(thetaf);
      v.y = p.y + r*cos(phif);
      v.z = p.z + r*sin(phif)*cos(thetaf);
    }
    if (phi == 0) continue;

    for (uniform int theta=1; theta<=numTheta; theta++)
    {
      uniform int p00 = (phi-1)*numTheta+theta-1;
      uniform int p01 = (phi-1)*numTheta+theta%numTheta;
      uniform int p10 = phi*numTheta+theta-1;
      uniform int p11 = phi*numTheta+theta%numTheta;

      if (phi > 1) {
        triangles[tri].v0 = p10;
        triangles[tri].v1 = p01;
        triangles[tri].v2 = p00;
        tri++;
      }

      if (phi < numPhi) {
        triangles[tri].v0 = p11;
        triangles[tri].v1 = p01;
        triangles[tri].v2 = p10;
        tri++;
      }
    }
  }

  rtcCommitGeometry(geom);
  uniform unsigned int geomID = rtcAttachGeometry(scene,geom);
  rtcReleaseGeometry(geom);
  return geomID;
}

/* creates a ground plane */
uniform unsigned int createGroundPlane (RTCScene scene)
{
  /* create a triangulated plane with 2 triangles and 4 vertices */
  RTCGeometry geom = rtcNewGeometry (g_device, RTC_GEOMETRY_TYPE_TRIANGLE);

  /* set vertices */
  uniform Vertex* uniform vertices = (uniform Vertex* uniform) rtcSetNewGeometryBuffer(geom,RTC_BUFFER_TYPE_VERTEX,0,RTC_FORMAT_FLOAT3,sizeof(uniform Vertex),4);
  vertices[0].x = -10; vertices[0].y = -2; vertices[0].z = -10;
  vertices[1].x = -10; vertices[1].y = -2; vertices[1].z = +10;
  vertices[2].x = +10; vertices[2].y = -2; vertices[2].z = -10;
  vertices[3].x = +10; vertices[3].y = -2; vertices[3].z = +10;

  /* set triangles */
  uniform Triangle* uniform triangles = (uniform Triangle* uniform) rtcSetNewGeometryBuffer(geom,RTC_BUFFER_TYPE_INDEX,0,RTC_FORMAT_UINT3,sizeof(uniform Triangle),2);
  triangles[0].v0 = 0; triangles[0].v1 = 1; triangles[0].v2 = 2;
  triangles[1].v0 = 1; triangles[1].v1 = 3; triangles[1].v2 = 2;

  rtcCommitGeometry(geom);
  uniform unsigned int geomID = rtcAttachGeometry(scene,geom);
  rtcReleaseGeometry(geom);
  return geomID;
}

/* called by the C++ code for initialization */
export void device_init (uniform int8* uniform cfg)
{
  TutorialData_Constructor(&data);
  
  /* create scene */
  data.g_scene = g_scene = rtcNewScene(g_device);
  rtcSetSceneBuildQuality(data.g_scene,RTC_BUILD_QUALITY_LOW);
  rtcSetSceneFlags(data.g_scene,RTC_SCENE_FLAG_DYNAMIC);

  /* create scene with 4 triangulated spheres */
  data.g_scene1 = rtcNewScene(g_device);
  createTriangulatedSphere(data.g_scene1,make_Vec3f( 0, 0,+1),0.5f);
  createTriangulatedSphere(data.g_scene1,make_Vec3f(+1, 0, 0),0.5f);
  createTriangulatedSphere(data.g_scene1,make_Vec3f( 0, 0,-1),0.5f);
  createTriangulatedSphere(data.g_scene1,make_Vec3f(-1, 0, 0),0.5f);
  rtcCommitScene (data.g_scene1);

  /* instantiate geometry */
  data.g_instance0 = rtcNewGeometry (g_device, RTC_GEOMETRY_TYPE_INSTANCE);
  rtcSetGeometryInstancedScene(data.g_instance0,data.g_scene1);
  rtcSetGeometryTimeStepCount(data.g_instance0,1);
  data.g_instance1 = rtcNewGeometry (g_device, RTC_GEOMETRY_TYPE_INSTANCE);
  rtcSetGeometryInstancedScene(data.g_instance1,data.g_scene1);
  rtcSetGeometryTimeStepCount(data.g_instance1,1);
  data.g_instance2 = rtcNewGeometry (g_device, RTC_GEOMETRY_TYPE_INSTANCE);
  rtcSetGeometryInstancedScene(data.g_instance2,data.g_scene1);
  rtcSetGeometryTimeStepCount(data.g_instance2,1);
  data.g_instance3 = rtcNewGeometry (g_device, RTC_GEOMETRY_TYPE_INSTANCE);
  rtcSetGeometryInstancedScene(data.g_instance3,data.g_scene1);
  rtcSetGeometryTimeStepCount(data.g_instance3,1);
  rtcAttachGeometry(data.g_scene,data.g_instance0);
  rtcAttachGeometry(data.g_scene,data.g_instance1);
  rtcAttachGeometry(data.g_scene,data.g_instance2);
  rtcAttachGeometry(data.g_scene,data.g_instance3);
  rtcReleaseGeometry(data.g_instance0);
  rtcReleaseGeometry(data.g_instance1);
  rtcReleaseGeometry(data.g_instance2);
  rtcReleaseGeometry(data.g_instance3);
  createGroundPlane(data.g_scene);

  /* set all colors */
  data.colors[0][0] = make_Vec3f(0.25f, 0.f, 0.f);
  data.colors[0][1] = make_Vec3f(0.50f, 0.f, 0.f);
  data.colors[0][2] = make_Vec3f(0.75f, 0.f, 0.f);
  data.colors[0][3] = make_Vec3f(1.00f, 0.f, 0.f);

  data.colors[1][0] = make_Vec3f(0.f, 0.25f, 0.f);
  data.colors[1][1] = make_Vec3f(0.f, 0.50f, 0.f);
  data.colors[1][2] = make_Vec3f(0.f, 0.75f, 0.f);
  data.colors[1][3] = make_Vec3f(0.f, 1.00f, 0.f);

  data.colors[2][0] = make_Vec3f(0.f, 0.f, 0.25f);
  data.colors[2][1] = make_Vec3f(0.f, 0.f, 0.50f);
  data.colors[2][2] = make_Vec3f(0.f, 0.f, 0.75f);
  data.colors[2][3] = make_Vec3f(0.f, 0.f, 1.00f);

  data.colors[3][0] = make_Vec3f(0.25f, 0.25f, 0.f);
  data.colors[3][1] = make_Vec3f(0.50f, 0.50f, 0.f);
  data.colors[3][2] = make_Vec3f(0.75f, 0.75f, 0.f);
  data.colors[3][3] = make_Vec3f(1.00f, 1.00f, 0.f);
}

/* task that renders a single screen tile */
Vec3f renderPixelStandard(const uniform TutorialData& data, float x, float y, const uniform ISPCCamera& camera, uniform RayStats& stats)
{
  uniform RTCIntersectContext context;
  rtcInitIntersectContext(&context);
  
  /* initialize ray */
  Ray ray = make_Ray(make_Vec3f(camera.xfm.p), make_Vec3f(normalize(x*camera.xfm.l.vx + y*camera.xfm.l.vy + camera.xfm.l.vz)), 0.0f, inf);

  /* intersect ray with scene */
  rtcIntersectV(data.g_scene,&context,RTCRayHit_(ray));
  RayStats_addRay(stats);

  /* shade pixels */
  Vec3f color = make_Vec3f(0.0f);
  if (ray.geomID != RTC_INVALID_GEOMETRY_ID)
  {
    /* calculate shading normal in world space */
    Vec3f Ns = ray.Ng;
    if (ray.instID[0] != RTC_INVALID_GEOMETRY_ID)
      Ns = xfmVector(data.normal_xfm[ray.instID[0]],Ns);
    Ns = normalize(Ns);

    /* calculate diffuse color of geometries */
    Vec3f diffuse = make_Vec3f(1,1,1);
    if (ray.instID[0] != RTC_INVALID_GEOMETRY_ID)
      diffuse = data.colors[ray.instID[0]][ray.geomID];
    color = color + diffuse*0.5;

    /* initialize shadow ray */
    Vec3f lightDir = normalize(make_Vec3f(-1,-1,-1));
    Ray shadow = make_Ray(ray.org + ray.tfar*ray.dir, neg(lightDir), 0.001f, inf);

    /* trace shadow ray */
    rtcOccludedV(data.g_scene,&context,RTCRay_(shadow));
    RayStats_addShadowRay(stats);

    /* add light contribution */
    if (shadow.tfar >= 0.0f)
      color = color + diffuse*clamp(-dot(lightDir,Ns),0.0f,1.0f);
  }
  return color;
}

/* renders a single screen tile */
void renderTileStandard(uniform int taskIndex,
                        uniform int threadIndex,
                        uniform int* uniform pixels,
                        const uniform unsigned int width,
                        const uniform unsigned int height,
                        const uniform float time,
                        const uniform ISPCCamera& camera,
                        const uniform int numTilesX,
                        const uniform int numTilesY)
{
  const uniform unsigned int tileY = taskIndex / numTilesX;
  const uniform unsigned int tileX = taskIndex - tileY * numTilesX;
  const uniform unsigned int x0 = tileX * TILE_SIZE_X;
  const uniform unsigned int x1 = min(x0+TILE_SIZE_X,width);
  const uniform unsigned int y0 = tileY * TILE_SIZE_Y;
  const uniform unsigned int y1 = min(y0+TILE_SIZE_Y,height);

  foreach_tiled (y = y0 ... y1, x = x0 ... x1)
  {
    /* calculate pixel color */
    Vec3f color = renderPixelStandard(data, (float)x,(float)y,camera,g_stats[threadIndex]);

    /* write color to framebuffer */
    unsigned int r = (unsigned int) (255.0f * clamp(color.x,0.0f,1.0f));
    unsigned int g = (unsigned int) (255.0f * clamp(color.y,0.0f,1.0f));
    unsigned int b = (unsigned int) (255.0f * clamp(color.z,0.0f,1.0f));
    pixels[y*width+x] = (b << 16) + (g << 8) + r;
  }
}

/* renders a single screen tile */
void renderTileStandardStream(uniform int taskIndex,
                              uniform int threadIndex,
                              uniform int* uniform pixels,
                              const uniform unsigned int width,
                              const uniform unsigned int height,
                              const uniform float time,
                              const uniform ISPCCamera& camera,
                              const uniform int numTilesX,
                              const uniform int numTilesY)
{
  const uniform unsigned int tileY = taskIndex / numTilesX;
  const uniform unsigned int tileX = taskIndex - tileY * numTilesX;
  const uniform unsigned int x0 = tileX * TILE_SIZE_X;
  const uniform unsigned int x1 = min(x0+TILE_SIZE_X,width);
  const uniform unsigned int y0 = tileY * TILE_SIZE_Y;
  const uniform unsigned int y1 = min(y0+TILE_SIZE_Y,height);

  uniform RayStats& stats = g_stats[threadIndex];

  Ray primary_stream[TILE_SIZE_X*TILE_SIZE_Y];
  Ray shadow_stream[TILE_SIZE_X*TILE_SIZE_Y];
  Vec3f color_stream[TILE_SIZE_X*TILE_SIZE_Y];
  bool valid_stream[TILE_SIZE_X*TILE_SIZE_Y];

  /* generate stream of primary rays */
  uniform int N = 0;
  foreach_tiled (y = y0 ... y1, x = x0 ... x1)
  {
    /* ISPC workaround for mask == 0 */
    if (all(__mask == 0)) continue;

    /* initialize variables */
    color_stream[N] = make_Vec3f(0.0f);
    bool mask = __mask; unmasked { valid_stream[N] = mask; }

    /* initialize ray */
    Ray& primary = primary_stream[N];
    mask = __mask; unmasked { // invalidates inactive rays
      primary.tnear = mask ? 0.0f         : (float)(pos_inf);
      primary.tfar  = mask ? (float)(inf) : (float)(neg_inf);
    }
    init_Ray(primary, make_Vec3f(camera.xfm.p), make_Vec3f(normalize((float)x*camera.xfm.l.vx + (float)y*camera.xfm.l.vy + camera.xfm.l.vz)), primary.tnear, primary.tfar);

    N++;
    RayStats_addRay(stats);
  }

  Vec3f lightDir = normalize(make_Vec3f(-1,-1,-1));

  /* trace rays */
  uniform RTCIntersectContext primary_context;
  rtcInitIntersectContext(&primary_context);
  primary_context.flags = g_iflags_coherent;
  rtcIntersectVM(data.g_scene,&primary_context,(varying RTCRayHit* uniform)&primary_stream,N,sizeof(Ray));

  /* terminate rays and update color */
  N = -1;
  foreach_tiled (y = y0 ... y1, x = x0 ... x1)
  {
    N++;
    /* ISPC workaround for mask == 0 */
    if (all(__mask == 0)) continue;

    /* invalidate shadow rays by default */
    Ray& shadow = shadow_stream[N];
    unmasked {
      shadow.tnear = (float)(pos_inf);
      shadow.tfar  = (float)(neg_inf);
    }

    /* ignore invalid rays */
    if (valid_stream[N] == false) continue;

    /* terminate rays that hit nothing */
    if (primary_stream[N].geomID == RTC_INVALID_GEOMETRY_ID) {
      valid_stream[N] = false;
      continue;
    }

    /* calculate shading normal in world space */
    Ray& primary = primary_stream[N];
    Vec3f Ns = primary.Ng;
    if (primary.instID[0] != RTC_INVALID_GEOMETRY_ID)
      Ns = xfmVector(data.normal_xfm[primary.instID[0]],Ns);
    Ns = normalize(Ns);

    /* calculate diffuse color of geometries */
    Vec3f diffuse = make_Vec3f(1,1,1);
    if (primary.instID[0] != RTC_INVALID_GEOMETRY_ID)
      diffuse = data.colors[primary.instID[0]][primary.geomID];
    color_stream[N] = color_stream[N] + diffuse*0.5;

    /* initialize shadow ray tnear/tfar */
    bool mask = __mask; unmasked {
      shadow.tnear = mask ? 0.001f       : (float)(pos_inf);
      shadow.tfar  = mask ? (float)(inf) : (float)(neg_inf);
    }
    init_Ray(shadow, primary.org + primary.tfar*primary.dir, neg(lightDir), shadow.tnear, shadow.tfar);

    RayStats_addShadowRay(stats);
  }
  N++;

  /* trace shadow rays */
  uniform RTCIntersectContext shadow_context;
  rtcInitIntersectContext(&shadow_context);
  shadow_context.flags = g_iflags_coherent;
  rtcOccludedVM(data.g_scene,&shadow_context,(varying RTCRay* uniform)&shadow_stream,N,sizeof(Ray));

  /* add light contribution */
  N = -1;
  foreach_tiled (y = y0 ... y1, x = x0 ... x1)
  {
    N++;
    /* ISPC workaround for mask == 0 */
    if (all(__mask == 0)) continue;

    /* ignore invalid rays */
    if (valid_stream[N] == false) continue;

    /* calculate shading normal in world space */
    Ray& primary = primary_stream[N];
    Vec3f Ns = primary.Ng;
    if (primary.instID[0] != RTC_INVALID_GEOMETRY_ID)
      Ns = xfmVector(data.normal_xfm[primary.instID[0]],Ns);
    Ns = normalize(Ns);

    /* calculate diffuse color of geometries */
    Vec3f diffuse = make_Vec3f(1,1,1);
    if (primary.instID[0] != RTC_INVALID_GEOMETRY_ID)
      diffuse = data.colors[primary.instID[0]][primary.geomID];

    /* add light contribution */
    Ray& shadow = shadow_stream[N];
    if (shadow.tfar >= 0.0f) {
      color_stream[N] = color_stream[N] + diffuse*clamp(-dot(lightDir,Ns),0.0f,1.0f);
    }
  }
  N++;

  /* framebuffer writeback */
  N = 0;
  foreach_tiled (y = y0 ... y1, x = x0 ... x1)
  {
    /* ISPC workaround for mask == 0 */
    if (all(__mask == 0)) continue;

    /* write color to framebuffer */
    unsigned int r = (unsigned int) (255.0f * clamp(color_stream[N].x,0.0f,1.0f));
    unsigned int g = (unsigned int) (255.0f * clamp(color_stream[N].y,0.0f,1.0f));
    unsigned int b = (unsigned int) (255.0f * clamp(color_stream[N].z,0.0f,1.0f));
    pixels[y*width+x] = (b << 16) + (g << 8) + r;
    N++;
  }
}

/* task that renders a single screen tile */
task void renderTileTask(uniform int* uniform pixels,
                                 const uniform unsigned int width,
                                 const uniform unsigned int height,
                                 const uniform float time,
                                 const uniform ISPCCamera& camera,
                                 const uniform int numTilesX,
                                 const uniform int numTilesY)
{
  if (g_mode == MODE_NORMAL)
    renderTileStandard(taskIndex,threadIndex,pixels,width,height,time,camera,numTilesX,numTilesY);
  else
    renderTileStandardStream(taskIndex,threadIndex,pixels,width,height,time,camera,numTilesX,numTilesY);
}

export void renderFrameStandard (uniform int* uniform pixels,
                          const uniform unsigned int width,
                          const uniform unsigned int height,
                          const uniform float time,
                          const uniform ISPCCamera& camera)
{
  /* render all pixels */
  const uniform int numTilesX = (width +TILE_SIZE_X-1)/TILE_SIZE_X;
  const uniform int numTilesY = (height+TILE_SIZE_Y-1)/TILE_SIZE_Y;
  launch[numTilesX*numTilesY] renderTileTask(pixels,width,height,time,camera,numTilesX,numTilesY); sync;
}

/* called by the C++ code to render */
export void device_render (uniform int* uniform pixels,
                           const uniform unsigned int width,
                           const uniform unsigned int height,
                           const uniform float time,
                           const uniform ISPCCamera& camera)
{
  uniform float t0 = 0.7f*time;
  uniform float t1 = 1.5f*time;

  /* rotate instances around themselves */
  uniform LinearSpace3f xfm;
  xfm.vx = make_Vec3f(cos(t1),0,sin(t1));
  xfm.vy = make_Vec3f(0,1,0);
  xfm.vz = make_Vec3f(-sin(t1),0,cos(t1));

  /* calculate transformations to move instances in circle */
  for (uniform int i=0; i<4; i++) {
    uniform float t = t0+i*2.0f*M_PI/4.0f;
    data.instance_xfm[i] = make_AffineSpace3f(xfm,2.2f*make_Vec3f(+cos(t),0.0f,+sin(t)));
  }

  /* calculate transformations to properly transform normals */
  for (uniform int i=0; i<4; i++)
    data.normal_xfm[i] = transposed(rcp(data.instance_xfm[i].l));

  /* set instance transformations */
  rtcSetGeometryTransform(data.g_instance0,0,RTC_FORMAT_FLOAT3X4_COLUMN_MAJOR,(uniform float* uniform)&data.instance_xfm[0]);
  rtcSetGeometryTransform(data.g_instance1,0,RTC_FORMAT_FLOAT3X4_COLUMN_MAJOR,(uniform float* uniform)&data.instance_xfm[1]);
  rtcSetGeometryTransform(data.g_instance2,0,RTC_FORMAT_FLOAT3X4_COLUMN_MAJOR,(uniform float* uniform)&data.instance_xfm[2]);
  rtcSetGeometryTransform(data.g_instance3,0,RTC_FORMAT_FLOAT3X4_COLUMN_MAJOR,(uniform float* uniform)&data.instance_xfm[3]);

  /* update scene */
  rtcCommitGeometry(data.g_instance0);
  rtcCommitGeometry(data.g_instance1);
  rtcCommitGeometry(data.g_instance2);
  rtcCommitGeometry(data.g_instance3);
  rtcCommitScene (data.g_scene);
}

/* called by the C++ code for cleanup */
export void device_cleanup ()
{
  TutorialData_Destructor(&data);
}
