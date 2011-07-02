//
//  XMLDocument.h
//  xmlparser
//
//  Created by Christian Torres on 6/11/11.
//  Copyright 2011 clov3r.net. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "URLObject.h"

// When the class is going to be defined later
@class XMLElement;
@class XMLDocument;

// Delegate
@protocol XMLDelegate <NSObject>
@optional
- (void)finishedParsing;
@end

@interface XMLDocument : NSObject <NSXMLParserDelegate, URLObjectDelegate> {
@private
    id <XMLDelegate> delegate;
   	NSString *pathOfElementWithXHTMLType; // Hold the path of the element who's type="xhtml" so we can stop parsing when it's ended
    NSString *currentPath;
    NSXMLParser *xmlParser;
    XMLElement *root;
	NSError *error;
}

// Delegate to recieve data as it is parsed
@property (nonatomic, assign) id <XMLDelegate> delegate;

@property (nonatomic, retain) NSString *currentPath;

@property (nonatomic, retain) NSXMLParser *xmlParser;

@property (nonatomic, retain) XMLElement *root;

@property (nonatomic, retain) NSError *error;

@property (nonatomic, copy) NSString *pathOfElementWithXHTMLType;

- (id)initWithData:(NSData *)data error:(NSError **)outError;

- (id)initWithURLString:(NSString *)URLString;

- (id)initWithURLStringSync:(NSString *)URLString;

- (void)processDownloadedObject:(NSData *)data;

+ (XMLDocument *)documentWithData:(NSData *)data error:(NSError **)outError;

@end
