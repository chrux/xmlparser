//
//  XMLElement.h
//  xmlparser
//
//  Created by Christian Torres on 6/11/11.
//  Copyright 2011 clov3r.net. All rights reserved.
//

#import <Foundation/Foundation.h>
// Logging
#import "Log.h"

// Empty XHTML elements ( <!ELEMENT br EMPTY> in http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd )
#define ELEMENT_IS_EMPTY(e) ([e isEqualToString:@"br"] || [e isEqualToString:@"img"] || [e isEqualToString:@"input"] || \
                             [e isEqualToString:@"hr"] || [e isEqualToString:@"link"] || [e isEqualToString:@"base"] || \
                             [e isEqualToString:@"basefont"] || [e isEqualToString:@"frame"] || [e isEqualToString:@"meta"] || \
                             [e isEqualToString:@"area"] || [e isEqualToString:@"col"] || [e isEqualToString:@"param"])

@class XMLDocument;

@interface XMLElement : NSObject <NSXMLParserDelegate> {
@private
    XMLDocument *document; // nonretained, when it is no nil the element is in 1st level
    XMLElement *parent; // nonretained
    NSString *name;
    NSMutableString *value;
    NSMutableArray *children;
    NSDictionary *attributes;

    BOOL parseStructureAsContent;
}

@property (nonatomic, assign) XMLDocument *document;
@property (nonatomic, assign) XMLElement *parent;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSMutableString *value;
@property (nonatomic, retain) NSArray *children;
@property (nonatomic, retain) NSDictionary *attributes;

// Functions
@property (nonatomic, readonly) XMLElement *firstChild, *lastChild;

- (id)initWithDocument:(XMLDocument *)document;
- (XMLElement *)childNamed:(NSString *)name;
- (NSArray *)childrenNamed:(NSString *)name;
- (XMLElement *)childWithAttribute:(NSString *)attributeName value:(NSString *)attributeValue;
- (NSString *)attributeNamed:(NSString *)name;
- (XMLElement *)descendantWithPath:(NSString *)path;
- (NSString *)valueWithPath:(NSString *)path;

@end