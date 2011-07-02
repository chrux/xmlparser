//
//  XMLDocument.m
//  xmlparser
//
//  Created by Christian Torres on 6/11/11.
//  Copyright 2011 clov3r.net. All rights reserved.
//

#import "XMLDocument.h"
#import "XMLElement.h"
#import "URLObject.h"

@implementation XMLDocument

@synthesize delegate;
@synthesize pathOfElementWithXHTMLType;
@synthesize currentPath;
@synthesize xmlParser;
@synthesize root;
@synthesize error;

- (void)dealloc
{
    delegate = nil;
    pathOfElementWithXHTMLType = nil;
    currentPath = nil;
    xmlParser = nil;
    root = nil;
    error = nil;
    [super dealloc];
}

- (id)initWithData:(NSData *)data error:(NSError **)outError {
    
    self = [super init];
	if (self) {

        // Initialization code here.
        self.xmlParser= [[[NSXMLParser alloc] initWithData:data] autorelease];
        
        // Parse!
        [xmlParser setDelegate:self];
        [xmlParser setShouldProcessNamespaces:YES];
        [xmlParser setShouldReportNamespacePrefixes:YES];
        [xmlParser setShouldResolveExternalEntities:NO];
        [xmlParser parse];
        
        xmlParser = nil; // Release after parse
            
        if (self.error) {
			if (outError)
				*outError = self.error;
			[self release];
			return nil;
		}


	}
    
    self.currentPath = @"/";

 	return self;
}

- (id)initWithURLString:(NSString *)URLString
{
    
    URLObject *file = [[URLObject alloc] initWithString:URLString andAgent:@""];
    [file setDelegate:self];
    [file load];
    
    return self;
}

- (id)initWithURLStringSync:(NSString *)URLString
{
    
    URLObject *file = [[URLObject alloc] initWithString:URLString andAgent:@""];
    [file setDelegate:self];
    [file setSynchronously:YES];
    [self initWithData:[file load] error:NULL];
    
    return self;
}

- (void)processDownloadedObject:(NSData *)data {
    [self initWithData:data error:NULL];
}

+ (XMLDocument *)documentWithData:(NSData *)data error:(NSError **)outError {
	return [[[XMLDocument alloc] initWithData:data error:outError] autorelease];
}

#pragma mark XMLDocument Parsing

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName
                                        namespaceURI:(NSString *)namespaceURI
                                       qualifiedName:(NSString *)qName
                                          attributes:(NSDictionary *)attributeDict {
	
	self.root = [[[XMLElement alloc] initWithDocument:self] autorelease];
	root.name = elementName;
	root.attributes = attributeDict;
    [parser setDelegate:root];
    
}

- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError {
    
    // What happen if an error is perfomed
    _Log(@"NSXMLParser: parseErrorOccurred: %@", parseError);
    
}

#pragma mark -

#pragma mark Description function

- (NSString *)description {
	return root.description;
}

#pragma mark -

@end