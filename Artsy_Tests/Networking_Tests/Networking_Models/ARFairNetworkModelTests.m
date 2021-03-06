#import "ARPostFeedItem.h"
#import "ARPartnerShowFeedItem.h"

SpecBegin(ARFairNetworkModel);

describe(@"getFairInfo", ^{
    before(^{
        [OHHTTPStubs stubJSONResponseAtPath:@"/api/v1/fair/fair-id-1" withResponse:@{
            @"id" : @"fair-id-1",
            @"name" : @"The Fair Name",
            @"start_at" : @"1976-01-30T15:00:00+00:00",
            @"end_at" : @"1976-02-02T15:00:00+00:00"
        }];
    [OHHTTPStubs stubJSONResponseAtPath:@"/api/v1/related/layer/synthetic/main/artworks" withResponse:@[]];
    });

    it(@"updates original fair instance", ^{
        waitUntil(^(DoneCallback done) {

            Fair *fair = [Fair modelWithJSON:@{ @"id" : @"fair-id-1", @"name" : @"The Armory Show", @"organizer" : @{ @"profile_id" : @"fair-profile-id" } }];
            ARFairNetworkModel *networkModel = [[ARFairNetworkModel alloc] init];

            [networkModel getFairInfo:fair success:^(Fair *returnedFair) {
                expect(returnedFair).to.equal(fair);
                expect(fair.name).to.equal(@"The Fair Name");
                done();

            } failure:nil];
        });
    });

    it(@"maintains its maps", ^{

        waitUntil(^(DoneCallback done) {
            Fair *fair = [Fair modelWithJSON:@{ @"id" : @"fair-id-1", @"name" : @"The Armory Show", @"organizer" : @{ @"profile_id" : @"fair-profile-id" } }];
            fair.maps = @[[[Map alloc] init]];

            ARFairNetworkModel *networkModel = [[ARFairNetworkModel alloc] init];

            [networkModel getFairInfo:fair success:^(Fair *returnedFair) {

                expect(returnedFair).to.equal(fair);
                expect(fair.name).to.equal(@"The Fair Name");
                expect(fair.maps.count).to.equal(1);

                done();

            } failure:nil];
        });

    });
});

describe(@"getFairInfoWith ID", ^{
    before(^{
        [OHHTTPStubs stubJSONResponseAtPath:@"/api/v1/fair/fair-id-2" withResponse:@{
            @"id" : @"fair-id",
            @"name" : @"The Fair Name",
            @"start_at" : @"1976-01-30T15:00:00+00:00",
            @"end_at" : @"1976-02-02T15:00:00+00:00"
        }];
    });

    it(@"fetches and returns fair", ^{
         waitUntil(^(DoneCallback done) {

             ARFairNetworkModel *networkModel = [[ARFairNetworkModel alloc] init];

            [networkModel getFairInfoWithID:@"fair-id-2" success:^(Fair *returnedFair) {
                expect(returnedFair.name).to.equal(@"The Fair Name");
                done();

            } failure:nil];
         });

    });
});

describe(@"getShowFeedItems", ^{

    it(@"gets items", ^{
        [OHHTTPStubs stubJSONResponseAtPath:@"/api/v1/fair/fair-id-3/shows" withResponse:@{
            @"next" : @"some cursor",
            @"results" : @[ @{ @"id": @"show-id", @"name": @"Show Title", @"_type" : @"PartnerShow" } ]
        }];

        Fair *fair = [Fair modelWithJSON:@{ @"id" : @"fair-id-3", @"name" : @"The Armory Show", @"organizer" : @{ @"profile_id" : @"fair-profile-id" } }];

        // Keep the feed out here so that it doesn't become nil when weakified during the request.
        __block ARFairShowFeed *feed = [[ARFairShowFeed alloc] initWithFair:fair];

        waitUntil(^(DoneCallback done) {
            ARFairNetworkModel *networkModel = [[ARFairNetworkModel alloc] init];

            [networkModel getShowFeedItems:feed success:^(NSOrderedSet *orderedSet) {

                expect(orderedSet.count).to.equal(1);
                expect(orderedSet[0]).to.beKindOf([ARPartnerShowFeedItem class]);

                ARPartnerShowFeedItem *item = orderedSet[0];
                expect(item.show.name).to.equal(@"Show Title");

                done();

            } failure:^(NSError *error) {


            }];

        });
    });
});


it(@"getPosts", ^{
    before(^{
        [OHHTTPStubs stubJSONResponseAtPath:@"/api/v1/profile/fair-profile-id/posts" withResponse:@{
            @"cursor" : @"some cursor",
            @"results" : @[ @{ @"id": @"post-id", @"title": @"Post Title", @"_type" : @"Post" } ]
        }];
    });

    it(@"returns feed timeline", ^{

        waitUntil(^(DoneCallback done) {

            Fair *fair = [Fair modelWithJSON:@{ @"id" : @"fair-id-4", @"name" : @"The Armory Show", @"organizer" : @{ @"profile_id" : @"fair-profile-id" } }];
            ARFairNetworkModel *networkModel = [[ARFairNetworkModel alloc] init];

            [networkModel getPostsForFair:fair success:^(ARFeedTimeline *feedTimeline) {

                expect([feedTimeline numberOfItems]).to.equal(1);

                ARPostFeedItem *item = (ARPostFeedItem *) [feedTimeline itemAtIndex:0];
                expect(item).toNot.beNil();
                expect([item feedItemID]).to.equal(@"post-id");

                done();
            }];

        });
    });
});

describe(@"getOrderedSets", ^{
    before(^{
        [OHHTTPStubs stubJSONResponseAtPath:@"/api/v1/sets" withResponse:@[
            @{ @"id": @"52ded6edc9dc24bccc0000a4", @"key": @"curator", @"name" : @"Highlights from Art World Influencers", @"item_type" : @"FeaturedLink" },
            @{ @"id": @"52ded6edc9dc24bccc0000a5", @"key": @"curator", @"name" : @"Other Highlights", @"item_type" : @"FeaturedLink" },
            @{ @"id": @"52ded6edc9dc24bccc0000b5", @"key": @"something else", @"name" : @"Something Else", @"item_type" : @"FeaturedLink" }
        ]];

    });

    it(@"returns ordered sets by key", ^{
        waitUntil(^(DoneCallback done) {

            Fair *fair = [Fair modelWithJSON:@{ @"id" : @"fair-id-5", @"name" : @"The Armory Show", @"organizer" : @{ @"profile_id" : @"fair-profile-id" } }];
            ARFairNetworkModel *networkModel = [[ARFairNetworkModel alloc] init];

            [networkModel getOrderedSetsForFair:fair success:^(NSMutableDictionary *orderedSets) {
                expect(orderedSets.count).to.equal(2);

                NSArray *curatorOrderedSets = orderedSets[@"curator"];
                expect(curatorOrderedSets).toNot.beNil();
                expect(curatorOrderedSets.count).to.equal(2);

                OrderedSet *first = (OrderedSet *) curatorOrderedSets[0];
                expect(first).toNot.beNil();
                expect(first.orderedSetID).to.equal(@"52ded6edc9dc24bccc0000a4");
                expect(first.name).to.equal(@"Highlights from Art World Influencers");
                expect(first.orderedSetDescription).to.beNil();

                // TODO: item type

                done();

            } failure:^(NSError *error) {

            }];
        });
    });
});

describe(@"getMapInfo", ^{
    before(^{
        [OHHTTPStubs stubJSONResponseAtPath:@"/api/v1/maps" withParams:@{@"fair_id" : @"fair-id-6" } withResponse:@[@{@"_id" : @"map-id"}]];
    });

    it(@"returns maps for fair", ^{
        waitUntil(^(DoneCallback done) {

            Fair *fair = [Fair modelWithJSON:@{ @"id" : @"fair-id-6", @"name" : @"The Armory Show", @"organizer" : @{ @"profile_id" : @"fair-profile-id" } }];
            ARFairNetworkModel *networkModel = [[ARFairNetworkModel alloc] init];

            [networkModel getMapInfoForFair:fair success:^(NSArray *maps) {

                expect(fair.maps).to.equal(maps);
                expect(maps.count).to.equal(1);

                done();

            } failure:^(NSError *error) {
                
            }];
        });

    });
});


SpecEnd
