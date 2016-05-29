//
//  Game.m
//  Go Game
//
//  Created by Hung Ga 123 on 5/24/16.
//  Copyright © 2016 HungVu. All rights reserved.
//

#import "Game.h"

@implementation Game
- (instancetype)init {
    self = [super init];
    if (self) {
        _goban = [Goban emptyMutableBoardArray];
        _turn = GobanBlackSpotString;
        _komi = GobanKomiAmount;
    }
    
    return self;
}

- (void)playMoveAtRow:(int)row column:(int)column forColor:(NSString *)color {
    self.previousStateOfBoard = [[NSMutableArray alloc] initWithArray:self.goban copyItems:YES];
    self.goban[row][column] = color;
    [self checkLifeOfAdjacentEnemyStones:row andForColumnValue:column];
    
    self.moveNumber = self.moveNumber + 1;
    self.blackPassed = NO;
    self.whitePassed = NO;
    self.turn = [color isEqualToString:GobanBlackSpotString] ? GobanWhiteSpotString : GobanBlackSpotString;
}

- (BOOL)isInBounds:(int)rowValue andForColumnValue:(int)columnValue {
    BOOL stoneWasOutOfBounds = rowValue < 0 ||
    rowValue > GobanRowLength - 1 ||
    columnValue < 0 ||
    columnValue > GobanColumnLength - 1;
    return !stoneWasOutOfBounds;
}

-(BOOL)isLegalMove:(int)rowValue andForColumnValue:(int)columnValue {
    // Check if given move was in bounds
    if(![self isInBounds:rowValue andForColumnValue:columnValue]) {
        NSLog(@"Illegal move: move was out of bounds");
        return NO;
    }
    // Check if the move has already been played
    if(![self.goban[rowValue][columnValue] isEqualToString:GobanEmptySpotString]) {
        NSLog(@"Illegal move: Move has already been played");
        return NO;
    }
    
    // Check if space has liberties still
    BOOL hasLiberties = NO;
    // Check right for liberties
    if(!hasLiberties &&
       [self isInBounds:(rowValue + 1) andForColumnValue:columnValue] &&
       [self.goban[rowValue + 1][columnValue] isEqualToString:GobanEmptySpotString]) {
        hasLiberties = YES;
    }
    // Check left for liberties
    if(!hasLiberties && [self isInBounds:(rowValue-1) andForColumnValue:columnValue] &&
       [self.goban[rowValue-1][columnValue] isEqualToString:GobanEmptySpotString]) {
        hasLiberties = YES;
    }
    // Check down for liberties
    if(!hasLiberties &&
       [self isInBounds:rowValue andForColumnValue:(columnValue+1)] &&
       [self.goban[rowValue][columnValue+1] isEqualToString:GobanEmptySpotString]) {
        hasLiberties = YES;
    }
    // Check up for liberties
    if(!hasLiberties &&
       [self isInBounds:rowValue andForColumnValue:(columnValue-1)] &&
       [self.goban[rowValue][columnValue-1] isEqualToString:GobanEmptySpotString]) {
        hasLiberties = YES;
    }
    // Check if any liberties were found and return NO (and print message) if they weren't
    if(!hasLiberties) {
        NSMutableArray *savedStateOfBoard = [Goban emptyMutableBoardArray];
        
        // Saving the state of the board
        for(int i = 0; i < self.goban.count; i++) {
            for(int j = 0; j < self.goban.count ; j++) {
                if([self.goban[j][i] isEqualToString:GobanEmptySpotString]) {
                    savedStateOfBoard[j][i] = GobanEmptySpotString;
                }
                else if([self.goban[j][i] isEqualToString:GobanBlackSpotString]) {
                    savedStateOfBoard[j][i] = GobanBlackSpotString;
                }
                else if([self.goban[j][i] isEqualToString:GobanWhiteSpotString]) {
                    savedStateOfBoard[j][i] = GobanWhiteSpotString;
                }
            }
        }
        
        // Play the move and then set it back if it's not legal
        long tempWhiteCaptureCount = self.capturedWhiteStones;
        long tempBlackCaptureCount = self.capturedBlackStones;
        self.goban[rowValue][columnValue] = self.turn;
        [self checkLifeOfAdjacentEnemyStones:rowValue andForColumnValue:columnValue];
        [Goban printBoardToConsole:self.goban];
        
        //Check if any adjacent stones died, once they died, check if they match the previous board and if they do, we have a ko, if they don't then we don't
        int deathRow;
        int deathColumn;
        BOOL stonesDied = NO;
        BOOL koFound = NO;
        BOOL suicide = NO;
        NSString *enemyColor = [[NSMutableString alloc] init];
        
        // Check if stones died to the right
        if([self isInBounds:(rowValue+1) andForColumnValue:columnValue] && [self.goban[rowValue+1][columnValue] isEqualToString:GobanEmptySpotString]) {
            deathRow = rowValue + 1;
            deathColumn = columnValue;
            stonesDied = YES;
        }
        // Check if stones died to the left
        else if([self isInBounds:(rowValue - 1) andForColumnValue:columnValue] && [self.goban[rowValue - 1][columnValue] isEqualToString:GobanEmptySpotString]) {
            deathRow = rowValue - 1;
            deathColumn = columnValue;
            stonesDied = YES;
        }
        // Check if stones died to the up
        else if([self isInBounds:rowValue andForColumnValue:(columnValue+1)] && [self.goban[rowValue][columnValue+1] isEqualToString:GobanEmptySpotString]) {
            deathRow = rowValue;
            deathColumn = columnValue + 1;
            stonesDied = YES;
        }
        // Check if stones died to the down
        else if([self isInBounds:rowValue andForColumnValue:(columnValue-1)] && [self.goban[rowValue][columnValue-1] isEqualToString:GobanEmptySpotString]) {
            deathRow = rowValue;
            deathColumn = columnValue - 1;
            stonesDied = YES;
        }
        
        if(stonesDied) {
            // Get whose move it is
            if([self.turn isEqualToString:GobanBlackSpotString]) {
                enemyColor = GobanWhiteSpotString;
            }
            else {
                enemyColor = GobanBlackSpotString;
            }
            
            // Check if this new board matches the previous board
            if([self.goban isEqualToArray:self.previousStateOfBoard]) {
                //Show warning
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Ko" message:@"" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                [alert show];
                koFound = YES;
            }
            
            //Setting the board back to its saved state
            for(int i = 0;i < self.goban.count; i++) {
                for(int j=0;j<[self.goban count];j++) {
                    if([savedStateOfBoard[j][i] isEqualToString:GobanEmptySpotString]) {
                        self.goban[j][i] = GobanEmptySpotString;
                    }
                    else if([savedStateOfBoard[j][i] isEqualToString:GobanBlackSpotString]) {
                        self.goban[j][i] = GobanBlackSpotString;
                    }
                    else if([savedStateOfBoard[j][i] isEqualToString:GobanWhiteSpotString]) {
                        self.goban[j][i] = GobanWhiteSpotString;
                    }
                }
            }
            
            //Restore the number of captured stones
            [self setCapturedWhiteStones:tempWhiteCaptureCount];
            [self setCapturedBlackStones:tempBlackCaptureCount];
            [Goban printBoardToConsole:self.goban];
            if(koFound) {
                return NO;
            }
        }
        else
        {
            //If no stones died, check if the move was a suicide move
            //Check if the move was a suicide move
            [self checkLifeOfStone:rowValue andForColumnValue:columnValue];
            //If the space is now a + then it was a suicide
            if([self.goban[rowValue][columnValue] isEqualToString:GobanEmptySpotString])
            {
                suicide = YES;
            }
            
            //Set the board back to its previous state
            for(int i=0;i<[self.goban count];i++)
            {
                for(int j=0;j<[self.goban count];j++)
                {
                    if([savedStateOfBoard[j][i] isEqualToString:GobanEmptySpotString])
                    {
                        self.goban[j][i] = GobanEmptySpotString;
                    }
                    else if([savedStateOfBoard[j][i] isEqualToString:GobanBlackSpotString])
                    {
                        self.goban[j][i] = GobanBlackSpotString;
                    }
                    else if([savedStateOfBoard[j][i] isEqualToString:GobanWhiteSpotString])
                    {
                        self.goban[j][i] = GobanWhiteSpotString;
                    }
                }
            } //Board set back to its saved state
            
            
            self.goban[rowValue][columnValue] = GobanEmptySpotString;
            [self setCapturedWhiteStones:tempWhiteCaptureCount];
            [self setCapturedBlackStones:tempBlackCaptureCount];
            [Goban printBoardToConsole:self.goban];
            
            if(suicide)
            {
                NSLog(@"Illegal move: Suicide");
                return NO;
            }
        }
    }
    
    NSLog(@"Legal move");
    return YES;
}

- (BOOL)checkIfNodeHasBeenVisited:(NSMutableArray *)visitedNodeList
                      forRowValue:(int)rowValueToCheck
                andForColumnValue:(int)columnValueToCheck {
    BOOL hasBeenVisited = NO;
    Stone *stoneInVisitedNodeList = nil;
    for(int i = 0; i < visitedNodeList.count; i++) {
        stoneInVisitedNodeList = visitedNodeList[i];
        
        //Check if the coordinates match the coordinates of any nodes in the visited node queue
        if(stoneInVisitedNodeList.row == rowValueToCheck && stoneInVisitedNodeList.column == columnValueToCheck) {
            hasBeenVisited = YES;
            break;
        }
    }
    
    return hasBeenVisited;
}

- (void)checkLifeOfAdjacentEnemyStones:(int)rowValue andForColumnValue:(int)columnValue {
    NSString *myColor = self.goban[rowValue][columnValue];
    NSString *opponentColor = [myColor isEqualToString:GobanBlackSpotString] ? GobanWhiteSpotString : GobanBlackSpotString;
    
    //Check right
    if ([self isInBounds:(rowValue + 1) andForColumnValue:columnValue] &&
        [self.goban[rowValue + 1][columnValue] isEqualToString:opponentColor]) {
        [self checkLifeOfStone:(rowValue + 1) andForColumnValue:columnValue];
    }
    //Check left
    if([self isInBounds:(rowValue - 1) andForColumnValue:columnValue] &&
       [self.goban[rowValue - 1][columnValue] isEqualToString:opponentColor]) {
        [self checkLifeOfStone:(rowValue - 1) andForColumnValue:columnValue];
    }
    //Check down
    if([self isInBounds:rowValue andForColumnValue:(columnValue + 1)] && [self.goban[rowValue][columnValue + 1] isEqualToString:opponentColor]) {
        [self checkLifeOfStone:rowValue andForColumnValue:(columnValue + 1)];
    }
    //Check up
    if([self isInBounds:rowValue andForColumnValue:(columnValue - 1)] &&
       [self.goban[rowValue][columnValue - 1] isEqualToString:opponentColor]) {
        [self checkLifeOfStone:rowValue andForColumnValue:(columnValue - 1)];
    }
}

- (void)checkLifeOfStone:(int)rowValue andForColumnValue:(int)columnValue {
    NSString *allyColor = self.goban[rowValue][columnValue];
    BOOL stonesAreDead = YES;
    
    //
    // Do a breadth-first search to determine if the stone is alive
    //
    Stone *vertex = [[Stone alloc] initWithWithRow:rowValue column:columnValue];
    NSMutableArray *queue = [NSMutableArray array];
    NSMutableArray *visitedNodes = [NSMutableArray arrayWithObject:vertex];
    
    //Check spot to the right of vertex
    if([self isInBounds:(vertex.row + 1) andForColumnValue:vertex.column]) {
        if([self.goban[vertex.row + 1][vertex.column] isEqualToString:allyColor]) {
            Stone *point = [[Stone alloc] initWithWithRow:vertex.row + 1 column:columnValue];
            [visitedNodes addObject:point];
            [queue addObject:point];
        }
        else if([self.goban[vertex.row + 1][vertex.column] isEqualToString:GobanEmptySpotString]) {
            //If it is a free space then we're done!
            [queue removeAllObjects];
            stonesAreDead = NO;
        }
    }
    //Check spot to the left of the vertex
    if([self isInBounds:(vertex.row - 1) andForColumnValue:vertex.column] && stonesAreDead) {
        if([self.goban[vertex.row - 1][vertex.column] isEqualToString:allyColor]) {
            Stone *point = [[Stone alloc] initWithWithRow:vertex.row - 1 column:vertex.column];
            [visitedNodes addObject:point];
            [queue addObject:point];
        }
        else if([self.goban[vertex.row - 1][vertex.column] isEqualToString:GobanEmptySpotString]) {
            //If it is a free space then we're done!
            [queue removeAllObjects];
            stonesAreDead = NO;
        }
    }
    //Check spot below the vertex
    if([self isInBounds:vertex.row andForColumnValue:(vertex.column + 1)] && stonesAreDead) {
        if([self.goban[vertex.row][vertex.column + 1] isEqualToString:allyColor]) {
            Stone *point = [[Stone alloc] initWithWithRow:vertex.row column:vertex.column + 1];
            [visitedNodes addObject:point];
            [queue addObject:point];
        }
        else if([self.goban[vertex.row][vertex.column + 1] isEqualToString:GobanEmptySpotString]) {
            // If it is a free space then we're done!
            [queue removeAllObjects];
            stonesAreDead = NO;
        }
    }
    //Check the spot above the vertex
    if([self isInBounds:vertex.row andForColumnValue:(vertex.column - 1)] && stonesAreDead) {
        if([self.goban[vertex.row][vertex.column - 1] isEqualToString:allyColor]) {
            Stone *point = [[Stone alloc] initWithWithRow:vertex.row column:vertex.column - 1];
            [visitedNodes addObject:point];
            [queue addObject:point];
        }
        else if([self.goban[vertex.row][vertex.column - 1] isEqualToString:GobanEmptySpotString]) {
            //If it is a free space then we're done!
            [queue removeAllObjects];
            stonesAreDead = NO;
        }
    }
    
    //Loop until the queue is empty
    while(queue.count > 0) {
        
        Stone *topOfQueue = queue[0];
        [queue removeObjectAtIndex:0];
        
        //Check spot to the right of vertex
        if([self isInBounds:(topOfQueue.row + 1) andForColumnValue:topOfQueue.column] &&
           stonesAreDead &&
           ![self checkIfNodeHasBeenVisited:visitedNodes forRowValue:(topOfQueue.row + 1) andForColumnValue:topOfQueue.column]) {
            if([self.goban[topOfQueue.row + 1][topOfQueue.column] isEqualToString:allyColor]) {
                Stone *point = [[Stone alloc] initWithWithRow:topOfQueue.row + 1 column:topOfQueue.column];
                [visitedNodes addObject:point];
                [queue addObject:point];
            }
            else if([self.goban[topOfQueue.row + 1][topOfQueue.column] isEqualToString:GobanEmptySpotString]) {
                //If it is a free space then we're done!
                [queue removeAllObjects];
                stonesAreDead = NO;
            }
        }
        //Check spot to the left of the vertex
        if([self isInBounds:(topOfQueue.row - 1) andForColumnValue:topOfQueue.column] && stonesAreDead &&
           ![self checkIfNodeHasBeenVisited:visitedNodes forRowValue:(topOfQueue.row - 1) andForColumnValue:topOfQueue.column]) {
            if([self.goban[topOfQueue.row - 1][topOfQueue.column] isEqualToString:allyColor]) {
                Stone *point = [[Stone alloc] initWithWithRow:topOfQueue.row - 1 column:topOfQueue.column];
                [visitedNodes addObject:point];
                [queue addObject:point];
            }
            else if([self.goban[topOfQueue.row - 1][topOfQueue.column] isEqualToString:GobanEmptySpotString]) {
                // If it is a free space then we're done!
                [queue removeAllObjects];
                stonesAreDead = NO;
            }
        }
        //Check spot below the vertex
        if([self isInBounds:topOfQueue.row andForColumnValue:(topOfQueue.column + 1)] && stonesAreDead && ![self checkIfNodeHasBeenVisited:visitedNodes forRowValue:topOfQueue.row andForColumnValue:(topOfQueue.column + 1)]) {
            if([self.goban[topOfQueue.row][topOfQueue.column + 1] isEqualToString:allyColor]) {
                Stone *point = [[Stone alloc] initWithWithRow:topOfQueue.row column:topOfQueue.column + 1];
                [visitedNodes addObject:point];
                [queue addObject:point];
            }
            else if([self.goban[topOfQueue.row][topOfQueue.column + 1] isEqualToString:GobanEmptySpotString]) {
                // If it is a free space then we're done!
                [queue removeAllObjects];
                stonesAreDead = NO;
            }
        }
        //Check the spot above the vertex
        if([self isInBounds:topOfQueue.row andForColumnValue:(topOfQueue.column - 1)] && stonesAreDead &&
           ![self checkIfNodeHasBeenVisited:visitedNodes forRowValue:topOfQueue.row andForColumnValue:(topOfQueue.column - 1)]) {
            if([self.goban[topOfQueue.row][topOfQueue.column - 1] isEqualToString:allyColor]) {
                Stone *point = [[Stone alloc] initWithWithRow:topOfQueue.row column:topOfQueue.column - 1];
                [visitedNodes addObject:point];
                [queue addObject:point];
            }
            else if([self.goban[topOfQueue.row][topOfQueue.column - 1] isEqualToString:GobanEmptySpotString]) {
                // If it is a free space then we're done!
                [queue removeAllObjects];
                stonesAreDead = NO;
            }
        }
    }
    
    //If stones are dead, set them back to unplayed spots
    if(stonesAreDead) {
        [Goban printBoardToConsole:self.goban];
        [self killStones:visitedNodes];
    }
}

-(void)killStones:(NSMutableArray *)stonesToKill {
    
    //Check what color the stone in the 0th index is to get the color of the stone
    Stone *stone = stonesToKill[0];
    
    //Get the color of the stones that are dying
    NSString *dyingColor = self.goban[stone.row][stone.column];
    if([dyingColor isEqualToString:GobanBlackSpotString]) {
        //Add the number of dead stones to black's captured stone count
        //self.previousCapturedBlackStones = self.capturedBlackStones;
        self.capturedBlackStones = (self.capturedBlackStones + stonesToKill.count);
    }
    else {
        //Add the number of dead stones to white's captured stone count
        // self.previousCapturedWhiteStones = self.capturedWhiteStones;
        self.capturedWhiteStones = (self.capturedWhiteStones + [stonesToKill count]);
    }
    
    //This takes the nodes from the visited Nodes array and sets them back to "+"
    for(int i = 0; i < stonesToKill.count; i++) {
        stone = stonesToKill[i];
        self.goban[stone.row][stone.column] = GobanEmptySpotString;
    }
    
    NSLog(@"Killed stones");
    [Goban printBoardToConsole:self.goban];
    
    self.redrawBoardNeeded = YES;
}

- (void)markStoneClusterAsDeadFor:(int)rowValue andForColumnValue:(int)columnValue andForColor:(NSString *)color {
    
    //BFS
    //Put the coordinates in a point and then add the point to the queue and visited nodes list
    Stone *vertex = [[Stone alloc] initWithWithRow:rowValue column:columnValue];
    
    // 1. Mark the root as visited.
    NSMutableArray *queue = [[NSMutableArray alloc] init];
    NSMutableArray *visitedNodes = [NSMutableArray arrayWithObject:vertex];
    if([color isEqualToString:GobanBlackSpotString]) {
        self.goban[vertex.row][vertex.column] = GobanVisitedBlackSpotString;
    }
    else if([color isEqualToString:GobanWhiteSpotString]) {
        self.goban[vertex.row][vertex.column] = GobanVisitedWhiteSpotString;
    }
    
    // 2. Check for free spaces around the root, mark all nodes of the same color as visited. Add all adjacent nodes to the root as visited
    //Check all spots around where the vertex is
    
    //Check spot to the right of vertex
    if([self isInBounds:(vertex.row + 1) andForColumnValue:vertex.column]) {
        //If it is an ally color, add it to the visited queue and the actual queue
        if([self.goban[vertex.row + 1][vertex.column] isEqualToString:color]) {
            //Create a new point and insert it into the queue
            Stone *point = [[Stone alloc] initWithWithRow:vertex.row + 1 column:vertex.column];
            
            //Mark the object as visited and insert it to the end of the visited queue
            [visitedNodes addObject:point];
            //Insert the object into the end of the queue
            [queue addObject:point];
            
            //Change the spot on the board to lowercase
            if([color isEqualToString:GobanBlackSpotString]) {
                self.goban[vertex.row + 1][vertex.column] = GobanVisitedBlackSpotString;
            }
            else if([color isEqualToString:GobanWhiteSpotString]) {
                self.goban[vertex.row + 1][vertex.column] = GobanWhiteSpotString;
            }
        }
    }
    //Check spot to the left of the vertex
    if([self isInBounds:(vertex.row - 1) andForColumnValue:vertex.column]) {
        //If it is an ally color, add it to the visited queue and the actual queue
        if([self.goban[vertex.row - 1][vertex.column] isEqualToString:color]) {
            //Create a new point and insert it into the queue
            Stone *point = [[Stone alloc] initWithWithRow:vertex.row column:vertex.column];
            
            //Mark the object as visited and insert it to the end of the visited queue
            [visitedNodes addObject:point];
            //Insert the object into the end of the queue
            [queue addObject:point];
            
            //Change the spot on the board to lowercase
            if([color isEqualToString:GobanBlackSpotString]) {
                self.goban[vertex.row - 1][vertex.column] = GobanVisitedBlackSpotString;
            }
            else if([color isEqualToString:GobanBlackSpotString]) {
                self.goban[vertex.row-1][vertex.column] = GobanVisitedWhiteSpotString;
            }
        }
    }
    //Check spot to the up of vertex
    if([self isInBounds:vertex.row andForColumnValue:(vertex.column - 1)])
    {
        //If it is an ally color, add it to the visited queue and the actual queue
        if([self.goban[vertex.row][vertex.column - 1] isEqualToString:color])
        {
            //Create a new point and insert it into the queue
            Stone *point = [[Stone alloc] initWithWithRow:vertex.row column:vertex.column - 1];
            
            //Mark the object as visited and insert it to the end of the visited queue
            [visitedNodes addObject:point];
            //Insert the object into the end of the queue
            [queue addObject:point];
            
            //Change the spot on the board to lowercase
            if([color isEqualToString:GobanBlackSpotString])
            {
                self.goban[vertex.row][vertex.column - 1] = GobanVisitedBlackSpotString;
            }
            else if([color isEqualToString:GobanBlackSpotString])
            {
                self.goban[vertex.row][vertex.column - 1] = GobanVisitedWhiteSpotString;
            }
        }
    }
    //Check spot to the down of vertex
    if([self isInBounds:vertex.row andForColumnValue:(vertex.column + 1)]) {
        //If it is an ally color, add it to the visited queue and the actual queue
        if([self.goban[vertex.row][vertex.column + 1] isEqualToString:color]) {
            //Create a new point and insert it into the queue
            Stone *point = [[Stone alloc] initWithWithRow:vertex.row column:vertex.column + 1];
            
            //Mark the object as visited and insert it to the end of the visited queue
            [visitedNodes addObject:point];
            //Insert the object into the end of the queue
            [queue addObject:point];
            
            //Change the spot on the board to lowercase
            if([color isEqualToString:GobanBlackSpotString]) {
                self.goban[vertex.row][vertex.column + 1] = GobanVisitedBlackSpotString;
            }
            else if([color isEqualToString:GobanBlackSpotString]) {
                self.goban[vertex.row][vertex.column+1] = GobanVisitedWhiteSpotString;
            }
        }
    }
    
    //Check if node has been visited is what is broken
    
    //Loop until the queue is empty
    while (queue.count > 0) {
        // 1. Pick the vertex at the head of the queue
        Stone *topOfQueue = queue[0];
        
        // 2. Dequeue the vertex at the head of the queue, syntax: - (void)removeObjectAtIndex:(NSUInteger)index
        [queue removeObjectAtIndex:0];
        
        // 3. Mark all unvisited vertices as visited (only if they aren't visited already!)
        //Check spot to the right of vertex
        if([self isInBounds:(topOfQueue.row + 1) andForColumnValue:topOfQueue.column] &&
           ![self checkIfNodeHasBeenVisited:visitedNodes forRowValue:(topOfQueue.row + 1)
                          andForColumnValue:topOfQueue.column]) {
               //Change it's letter to lower case, add it to the visited queue and the actual queue
               if([self.goban[topOfQueue.row + 1][topOfQueue.column] isEqualToString:color]) {
                   //Create a new point and insert it into the queue
                   Stone *point = [[Stone alloc] initWithWithRow:topOfQueue.row + 1 column:topOfQueue.column];
                   
                   //Mark the object as visited and insert it to the end of the visited queue
                   [visitedNodes addObject:point];
                   //Insert the object into the end of the queue
                   [queue addObject:point];
                   
                   //Change the spot on the board to lowercase
                   if([color isEqualToString:GobanBlackSpotString]) {
                       self.goban[topOfQueue.row + 1][topOfQueue.column] = GobanVisitedBlackSpotString;
                   }
                   else if([color isEqualToString:GobanWhiteSpotString]) {
                       self.goban[topOfQueue.row + 1][topOfQueue.column] = GobanWhiteSpotString;
                   }
               }
           }
        //Check spot to the left of the vertex
        if([self isInBounds:(topOfQueue.row - 1) andForColumnValue:topOfQueue.column] &&
           ![self checkIfNodeHasBeenVisited:visitedNodes forRowValue:(topOfQueue.row - 1) andForColumnValue:topOfQueue.column]) {
            //If it is an ally color, add it to the visited queue and the actual queue
            if([self.goban[topOfQueue.row - 1][topOfQueue.column] isEqualToString:color]) {
                //Create a new point and insert it into the queue
                Stone *point = [[Stone alloc] initWithWithRow:topOfQueue.row - 1 column:columnValue];
                
                //Mark the object as visited and insert it to the end of the visited queue
                [visitedNodes addObject:point];
                //Insert the object into the end of the queue
                [queue addObject:point];
                
                //Change the spot on the board to lowercase
                if([color isEqualToString:GobanBlackSpotString]) {
                    self.goban[topOfQueue.row - 1][topOfQueue.column] = GobanVisitedBlackSpotString;
                }
                else if([color isEqualToString:GobanWhiteSpotString]) {
                    self.goban[topOfQueue.row - 1][topOfQueue.column] = GobanVisitedWhiteSpotString;
                }
            }
        }
        //Check spot below the vertex
        if([self isInBounds:topOfQueue.row andForColumnValue:(topOfQueue.column + 1)] &&
           ![self checkIfNodeHasBeenVisited:visitedNodes forRowValue:topOfQueue.row andForColumnValue:(topOfQueue.column + 1)]) {
            //If it is an ally color, add it to the visited queue and the actual queue
            if([self.goban[topOfQueue.row][topOfQueue.column + 1] isEqualToString:color]) {
                //Create a new point and insert it into the queue
                Stone *point = [[Stone alloc] initWithWithRow:topOfQueue.row column:topOfQueue.column + 1];
                
                //Mark the object as visited and insert it to the end of the visited queue
                [visitedNodes addObject:point];
                //Insert the object into the end of the queue
                [queue addObject:point];
                
                //Change the spot on the board to lowercase
                if([color isEqualToString:GobanBlackSpotString]) {
                    self.goban[topOfQueue.row][topOfQueue.column + 1] = GobanVisitedBlackSpotString;
                }
                else if([color isEqualToString:GobanWhiteSpotString]) {
                    self.goban[topOfQueue.row][topOfQueue.column + 1] = GobanVisitedWhiteSpotString;
                }
            }
        }
        //Check the spot above the vertex
        if([self isInBounds:topOfQueue.row andForColumnValue:(topOfQueue.column - 1)] &&
           ![self checkIfNodeHasBeenVisited:visitedNodes forRowValue:topOfQueue.row andForColumnValue:(topOfQueue.column - 1)]) {
            //If it is an ally color, add it to the visited queue and the actual queue
            if([self.goban[topOfQueue.row][topOfQueue.column - 1] isEqualToString:color])
            {
                //Create a new point and insert it into the queue
                Stone *point = [[Stone alloc] initWithWithRow:topOfQueue.row column:topOfQueue.column - 1];
                
                //Mark the object as visited and insert it to the end of the visited queue
                [visitedNodes addObject:point];
                //Insert the object into the end of the queue
                [queue addObject:point];
                
                //Change the spot on the board to lowercase
                if([color isEqualToString:GobanBlackSpotString]) {
                    self.goban[topOfQueue.row][topOfQueue.column - 1] = GobanVisitedBlackSpotString;
                }
                else if([color isEqualToString:GobanWhiteSpotString]) {
                    self.goban[topOfQueue.row][topOfQueue.column - 1] = GobanVisitedWhiteSpotString;
                }
            }
        }
    }
    
    //Set that the board needs to be redrawn
    self.redrawBoardNeeded = YES;
}

@end
