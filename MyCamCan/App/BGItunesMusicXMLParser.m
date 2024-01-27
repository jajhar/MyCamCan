////
////  BGItunesMusicXMLParser.m
////  Blog
////
////  Created by James Ajhar on 7/22/15.
////  Copyright (c) 2015 James Ajhar. All rights reserved.
////
//
//#import "BGItunesMusicXMLParser.h"
//#import "MusicItem.h"
//#import "AppData.h"
//#import "LocalSession.h"
//
//@interface BGItunesMusicXMLParser () <NSXMLParserDelegate>
//
//@property (strong) NSXMLParser *parser;
//
///** Contains the complete response
// */
//@property (strong) NSMutableArray *songs;
//
///** Current section being parsed
// */
//@property (strong) NSMutableDictionary *currentDictionary;
//
//// Properties used during the XML parsing
//@property (strong) NSString *previousElementName;
//@property (strong) NSString *elementName;
//@property (strong) NSMutableString *outString;
//
//@end
//
//
//@implementation BGItunesMusicXMLParser
//
//
//- (void)parseDocumentWithURL:(NSURL *)url {
//    
//    // Make an asynchronous call to the server
//    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
//    [request addValue:[AppData sharedInstance].localSession.oauthToken forHTTPHeaderField:@"token"];
//    
//    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
//    operation.responseSerializer = [AFXMLParserResponseSerializer serializer];
//    // We need to add this content type to be able to accept it and parse it
//    operation.responseSerializer.acceptableContentTypes = [NSSet setWithObject:@"application/atom+xml"];
//
////#ifdef DEBUG
////    // Disable cache during debugging
////    [operation setCacheResponseBlock:^NSCachedURLResponse *(NSURLConnection *connection, NSCachedURLResponse *cachedResponse) {
////        return nil;
////    }];
////#endif
//    
//    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
//        // Parse the XML
//        self.songs = [NSMutableArray array];
//        self.musicItems = [NSMutableArray array];
//        self.parser = [[NSXMLParser alloc] initWithData:operation.responseData];
//        self.parser.delegate = self;
//        self.parser.shouldProcessNamespaces = YES;
//        [self.parser parse];
//        
//    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
//        
//        // In case of error, display it on a alert view
//        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error Retrieving Songs"
//                                                            message:@"Please try again."
//                                                           delegate:nil
//                                                  cancelButtonTitle:@"OK"
//                                                  otherButtonTitles:nil];
//        [alertView show];
//        
//        NSLog(@"%@", [error localizedDescription]);
//        
//        [self.delegate parserDidFinishParsingDocument];
//
//    }];
//    
//    [operation start];
//
//}
//
//
//#pragma mark - NSXMLParserDelegate
//
//- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
//{
//    // Keep track of the previous element before start constructing the new one
//    self.previousElementName = self.elementName;
//    
//    if (qName) {
//        self.elementName = qName;
//    }
//    
//    // Create a dictionary for each entry
//    if ([qName isEqualToString:@"entry"]) {
//        self.currentDictionary = [NSMutableDictionary dictionary];
//    }
//    
//    // print all attributes for this element
//    NSEnumerator *attribs = [attributeDict keyEnumerator];
//    NSString *key, *value;
//    
//    if ([qName isEqualToString:@"link"]) {
//    
//        BOOL isPreviewLink = NO;
//        
//        while((key = [attribs nextObject]) != nil) {
//            value = [attributeDict objectForKey:key];
//            
//            if(!isPreviewLink) {
//                isPreviewLink = [value isEqualToString:@"Preview"] || [value isEqualToString:@"preview"];
//            }
//                        
//            if([key isEqualToString:@"href"] && isPreviewLink) {
//                [self.currentDictionary setObject:value forKey:qName];
//            }
//
//        }
//    }
//    
//    
//    // Reset the out String that we build as we read the XML inside this tag
//    self.outString = [NSMutableString string];
//}
//
//
//- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
//{
//    if (!self.elementName) {
//        return;
//    }
//    
//    [self.outString appendFormat:@"%@", string];
//}
//
//
//- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
//{
//    
////    NSLog(@"outString: %@", self.outString);
//    // Add an 'entry'
//    if ([qName isEqualToString:@"entry"]) {
//        [self.songs addObject:self.currentDictionary];
//        
//        self.currentDictionary = nil;
//    }
//    // Save 'id' as 'url'
//    else if ([qName isEqualToString:@"id"]) {
//        [self.currentDictionary setObject:self.outString forKey:@"url"];
//    }
//    // Save 'title'
//    else if ([qName isEqualToString:@"title"]) {
//        [self.currentDictionary setObject:self.outString forKey:qName];
//    }
//    // Save 'name', there's a nested 'im:name' inside 'im:collection', we should ignore it
//    else if ([qName isEqualToString:@"im:name"] && !self.currentDictionary[@"name"]) {
//        [self.currentDictionary setObject:self.outString forKey:[qName substringFromIndex:3]];
//    }
//    // Save 'artist' and 'price'
//    else if ([qName isEqualToString:@"im:artist"] || [qName isEqualToString:@"im:price"]) {
//        [self.currentDictionary setObject:self.outString forKey:[qName substringFromIndex:3]];
//    }
//    // Save image links
//    else if ([qName isEqualToString:@"im:image"]) {
//        if (self.currentDictionary[@"images"]) {
//            [self.currentDictionary[@"images"] addObject:self.outString];
//        } else {
//            [self.currentDictionary setObject:[NSMutableArray arrayWithObject:self.outString] forKey:@"images"];
//        }
//    }
//    
//    self.elementName = nil;
//}
//
//
//- (void)parserDidEndDocument:(NSXMLParser *)parser
//{
//    for(NSDictionary *songDict in self.songs) {
//        
//        MusicItem *item = [MusicItem musicItemWithBasicInfoDictionary:songDict];
//        [self.musicItems addObject:item];
//        
//    }
//    
//    [self.delegate parserDidFinishParsingDocument];
//}
//
//@end
