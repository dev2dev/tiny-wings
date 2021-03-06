/*
 *  Tiny Wings remake
 *  http://github.com/haqu/tiny-wings
 *
 *  Created by Sergey Tikhonov http://haqu.net
 *  Released under the MIT License
 *
 */

#import "GameLayer.h"
#import "Terrain.h"
#import "Hero.h"

@implementation GameLayer

@synthesize background = background_;
@synthesize terrain = terrain_;
@synthesize hero = hero_;

+ (CCScene*) scene {
    CCScene *scene = [CCScene node];
    [scene addChild:[GameLayer node]];
    return scene;
}

- (CCSprite*) generateBackground {

    int textureSize = 512;

    ccColor3B c = (ccColor3B){140,205,221};

    CCRenderTexture *rt = [CCRenderTexture renderTextureWithWidth:textureSize height:textureSize];
    [rt beginWithClear:(float)c.r/256.0f g:(float)c.g/256.0f b:(float)c.b/256.0f a:1];

    // layer 1: gradient

    float gradientAlpha = 0.5f;

    glDisable(GL_TEXTURE_2D);
    glDisableClientState(GL_TEXTURE_COORD_ARRAY);

    CGPoint vertices[4];
    ccColor4F colors[4];
    int nVertices = 0;

    vertices[nVertices] = CGPointMake(0, 0);
    colors[nVertices++] = (ccColor4F){0, 0, 0, gradientAlpha};
    vertices[nVertices] = CGPointMake(textureSize, 0);
    colors[nVertices++] = (ccColor4F){0, 0, 0, gradientAlpha};
    vertices[nVertices] = CGPointMake(0, textureSize/2);
    colors[nVertices++] = (ccColor4F){0, 0, 0, 0};
    vertices[nVertices] = CGPointMake(textureSize, textureSize/2);
    colors[nVertices++] = (ccColor4F){0, 0, 0, 0};

    glVertexPointer(2, GL_FLOAT, 0, vertices);
    glColorPointer(4, GL_FLOAT, 0, colors);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, (GLsizei)nVertices);

    glEnableClientState(GL_TEXTURE_COORD_ARRAY);
    glEnable(GL_TEXTURE_2D);	

    // layer 2: noise

    CCSprite *s = [CCSprite spriteWithFile:@"noise.png"];
    [s setBlendFunc:(ccBlendFunc){GL_DST_COLOR, GL_ZERO}];
    s.position = ccp(textureSize/2, textureSize/2);
    glColor4f(1,1,1,1);
    [s visit];

    [rt end];

    return [CCSprite spriteWithTexture:rt.sprite.texture];
}

- (void) createBox2DWorld {

    b2Vec2 gravity;
//    gravity.Set(0.0f, -9.8f);
    gravity.Set(0, -7);

    world = new b2World(gravity, true);
    world->SetContinuousPhysics(true);
}

- (id) init {
    
	if ((self = [super init])) {
		
        CGSize size = [[CCDirector sharedDirector] winSize];
        screenW = size.width;
        screenH = size.height;

        [self createBox2DWorld];

        self.background = [self generateBackground];
        background_.position = ccp(screenW/2,screenH/2);
        ccTexParams tp = {GL_NEAREST, GL_NEAREST, GL_REPEAT, GL_REPEAT};
        [background_.texture setTexParameters:&tp];
        [self addChild:background_];		

        self.terrain = [Terrain terrainWithWorld:world];
        [self addChild:terrain_];
		
        self.hero = [Hero heroWithWorld:world];
        [terrain_ addChild:hero_];

        self.isTouchEnabled = YES;
        tapDown = NO;

        [self scheduleUpdate];
    }
    return self;
}

- (void) dealloc {
    
	delete world;
	world = NULL;
	
	self.background = nil;
	self.terrain = nil;
	
	[super dealloc];
}

- (void) registerWithTouchDispatcher {
    [[CCTouchDispatcher sharedDispatcher] addTargetedDelegate:self priority:0 swallowsTouches:YES];
}

- (BOOL) ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event {
    tapDown = YES;
    return YES;
}

- (void) ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event {
    tapDown = NO;
}

- (void) update:(ccTime)dt {

    if (tapDown) {
		if (!hero_.awake) {
			[hero_ wake];
			tapDown = NO;
		} else {
			[hero_ dive];
		}
    }
    [hero_ limitVelocity];
    
    int32 velocityIterations = 2;
    int32 positionIterations = 1;
    world->Step(dt, velocityIterations, positionIterations);
    world->ClearForces();
    
    // update hero CCNode position
    [hero_ updateNodePosition];

    float scale = (screenH*4/5) / hero_.position.y;
    if (scale > 1) scale = 1;
    terrain_.scale = scale;
    
    terrain_.offsetX = hero_.position.x;

    // scroll background texture
    CGSize size = background_.textureRect.size;
    background_.textureRect = CGRectMake(terrain_.offsetX*0.2f, 0, size.width, size.height);
}

@end
