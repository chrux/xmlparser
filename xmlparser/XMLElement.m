//
//  XMLElement.m
//  xmlparser
//
//  Created by Christian Torres on 6/11/11.
//  Copyright 2011 clov3r.net. All rights reserved.
//

#import "XMLElement.h"
#import "XMLDocument.h"
#import "NSString+HTML.h" // Include here, because I used it here


@implementation XMLElement

@synthesize document;
@synthesize parent;
@synthesize name;
@synthesize value;
@synthesize children;
@synthesize attributes;

- (void)dealloc
{
    // No release because this is a references to other object
    document = nil;
    parent = nil;
    
    // Here we can do it
    name = nil;
    value = nil;
    children = nil;
    attributes = nil;
    [super dealloc];
}

- (id)initWithDocument:(XMLDocument *)xmlDocument {
    
	self = [super init];
	if (self) {
        // Initialization code here.
		self.document = xmlDocument;
    }
    
	return self;
    
}

#pragma mark Description function
/*
 * Usefull when we want to use NSLog to print the value
 */

- (NSString *)descriptionWithIndent:(NSString *)indent {
    
	NSMutableString *s = [NSMutableString string];
	[s appendFormat:@"%@<%@", indent, name];
	
	for (NSString *attribute in attributes)
		[s appendFormat:@" %@=\"%@\"", attribute, [attributes objectForKey:attribute]];
    
	NSString *trimVal = [value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
	if (trimVal.length > 25)
		trimVal = [NSString stringWithFormat:@"%@…", [trimVal substringToIndex:25]];
	
	if ( [children count] ) {
		[s appendString:@">\n"];
		
		NSString *childIndent = [indent stringByAppendingString:@"  "];
		
		if (trimVal.length)
			[s appendFormat:@"%@%@\n", childIndent, trimVal];
        
		for (XMLElement *child in children)
			[s appendFormat:@"%@\n", [child descriptionWithIndent:childIndent]];
		
		[s appendFormat:@"%@</%@>", indent, name];
	}
	else if (trimVal.length) {
		[s appendFormat:@">%@</%@>", trimVal, name];
	}
	else [s appendString:@"/>"];
	
	return s;

}

- (NSString *)description {
	return [self descriptionWithIndent:@""];
}

#pragma mark -

#pragma mark Node Access Functions

- (XMLElement *)firstChild { return [children count] > 0 ? [children objectAtIndex:0] : nil; }

- (XMLElement *)lastChild { return [children lastObject]; }

- (XMLElement *)childNamed:(NSString *)nodeName {
    
	for (XMLElement *child in children)
		if ([child.name isEqual:nodeName])
			return child;
	return nil;
    
}

- (NSArray *)childrenNamed:(NSString *)nodeName {
    
	NSMutableArray *array = [NSMutableArray array];
	for (XMLElement *child in children)
		if ([child.name isEqual:nodeName])
			[array addObject:child];
	return [[array copy] autorelease];
    
}

- (XMLElement *)childWithAttribute:(NSString *)attributeName value:(NSString *)attributeValue {
    
	for (XMLElement *child in children)
		if ([[child attributeNamed:attributeName] isEqual:attributeValue])
			return child;
	return nil;
    
}

- (NSString *)attributeNamed:(NSString *)attributeName {
	return [attributes objectForKey:attributeName];
}

- (XMLElement *)descendantWithPath:(NSString *)path {
    
	XMLElement *descendant = self;
	for (NSString *childName in [path componentsSeparatedByString:@"."])
		descendant = [descendant childNamed:childName];
	return descendant;
    
}

- (NSString *)valueWithPath:(NSString *)path {
    
	NSArray *components = [path componentsSeparatedByString:@"@"];
	XMLElement *descendant = [self descendantWithPath:[components objectAtIndex:0]];
	return [components count] > 1 ? [descendant attributeNamed:[components objectAtIndex:1]] : descendant.value;
    
}

#pragma mark -

#pragma mark XMLElement Parsing

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName
                                        namespaceURI:(NSString *)namespaceURI
                                       qualifiedName:(NSString *)qName
                                          attributes:(NSDictionary *)attributeDict {
    
    _Log(@"NSXMLParser: didStartElement: %@", qName);

    // Adjust path
    self.document.currentPath = [self.document.currentPath stringByAppendingPathComponent:qName];
    
    NSString *typeAttribute = [attributeDict objectForKey:@"type"];
    if ( typeAttribute && ( [typeAttribute isEqualToString:@"xhtml"] || [typeAttribute isEqualToString:@"html"] ) ) {
        parseStructureAsContent = YES;
        
        // Remember path so we can stop parsing structure when element ends
        self.document.pathOfElementWithXHTMLType = self.document.currentPath;
    }

    // Parse content as structure (Atom feeds with element type="xhtml")
    // - Use elementName not qualifiedName to ignore XML namespaces for XHTML entities
    if (parseStructureAsContent) {
        
        // Open XHTML tag
        [value appendFormat:@"<%@", elementName];
        
        // Add attributes
        for (NSString *key in attributeDict) {
            [value appendFormat:@" %@=\"%@\"", key,
             [[attributeDict objectForKey:key] stringByEncodingHTMLEntities]];
        }
        
        // End tag or close
        if (ELEMENT_IS_EMPTY(elementName)) {
            [value appendFormat:@" />", elementName];
        } else {
            [value appendFormat:@">", elementName];
        }
        //[pool drain];
        
        // Dont continue
        return;

    }
      
    XMLElement *child = [[[XMLElement alloc] initWithDocument:self.document] autorelease];
    child.parent = self;
    child.name = elementName;
    child.attributes = attributeDict;
        
    // Reset
    [child.value setString:@""];
        
    if (children)
        [children addObject:child];
    else
        children = [NSMutableArray arrayWithObject:child];

    [parser setDelegate:child];
    
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName 
                                      namespaceURI:(NSString *)namespaceURI
                                     qualifiedName:(NSString *)qName {
    
    _Log(@"NSXMLParser: didEndElement: %@", qName);
    
    // Parse content as structure (Atom feeds with element type="xhtml")
	// - Use elementName not qualifiedName to ignore XML namespaces for XHTML entities
	if (parseStructureAsContent) {
		
		// Check for finishing parsing structure as content
        // If it is part of the content (condition true), we enter here
		if (self.document.currentPath.length > self.document.pathOfElementWithXHTMLType.length) {
            
			// Close XHTML tag unless it is an empty element
			if (!ELEMENT_IS_EMPTY(elementName)) [value appendFormat:@"</%@>", elementName];
			
			// Adjust path & don't continue
			self.document.currentPath = [self.document.currentPath stringByDeletingLastPathComponent];
			
			// Return
			return;
			
		}
        
		// Finish
		parseStructureAsContent = NO;
		self.document.pathOfElementWithXHTMLType = nil;
		
		// Continue...
		
	}
    
    // Making some extra processing staff
    
    if (value) {
		
		// Remove newlines and whitespace from currentText
		[value setString:[value stringByRemovingNewLinesAndWhitespace]];
        
        // Here we can do some staffs such us let knows to a delegate the info we have
    
    }
    
    // Adjust path
	self.document.currentPath = [self.document.currentPath stringByDeletingLastPathComponent];
    
    if ( [self.document.root isEqual:self] && self.document.delegate ) {
        [self.document.delegate finishedParsing];
    }
    
    [parser setDelegate:parent];
    
}

- (void)parser:(NSXMLParser *)parser foundCDATA:(NSData *)CDATABlock {

    _Log(@"NSXMLParser: foundCDATA (%d bytes)", CDATABlock.length);
	
	// Remember characters
	NSString *string = nil;
	@try {
		
		// Try decoding with NSUTF8StringEncoding, if not with NSISOLatin1StringEncoding
		string = [[NSString alloc] initWithData:CDATABlock encoding:NSUTF8StringEncoding];
		if (!string) string = [[NSString alloc] initWithData:CDATABlock encoding:NSISOLatin1StringEncoding];
		
		// Add - No need to encode as CDATA should not be encoded as it's ignored by the parser
		if (string) {
            if ( value )
                [value appendString:string];
            else
                [NSMutableString stringWithString:string];
        }
		
	} @catch (NSException * e) {
	} @finally {
		[string release];
	}

}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {

	_Log(@"NSXMLParser: foundCharacters: %@", string);

	// Remember characters
	if (!parseStructureAsContent) {
		
		// Add characters normally
        if ( value ) {
            [value appendString:string];
        } else
            value = [NSMutableString stringWithString:string];
		
	} else {
		
        //NSLog(@"value %@ y string %@",value,string);
		// If parsing structure as content then we should encode characters
        if ( value )
            [value appendString:[string stringByEncodingHTMLEntities]];
        else
            value = [NSMutableString stringWithString:[string stringByEncodingHTMLEntities]];
		
	}

}

// Call if parsing error occured or parse was aborted
- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError {
    
    // What happen if an error is perfomed
	_Log(@"NSXMLParser: parseErrorOccurred: %@", parseError);
	
}

- (void)parser:(NSXMLParser *)parser validationErrorOccurred:(NSError *)validError {

	// Fail with error
    _Log(@"NSXMLParser: validationErrorOccurred: %@", validError);
	
}

#pragma mark -

@end
