/*
 *  E/17/100 - Gunathilaka R.M.S.M
 *  E/17/246 - Perera K.S.D.
*/

/*
 *  The scanner definition for COOL.
 */

/*
 *  Stuff enclosed in %{ %} in the first section is copied verbatim to the
 *  output, so headers and global definitions are placed here to be visible
 * to the code in the file.  Don't remove anything that was here initially
 */
%{
#include <cool-parse.h>
#include <stringtab.h>
#include <utilities.h>

/* The compiler assumes these identifiers. */
#define yylval cool_yylval
#define yylex  cool_yylex


/* Max size of STRING constants */
#define MAX_STR_CONST 1025
#define YY_NO_UNPUT   /* keep g++ happy */

extern FILE *fin; /* we read from this file */

/* define YY_INPUT so we read from the FILE fin:
 * This change makes it possible to use this scanner in
 * the Cool compiler.
 */
#undef YY_INPUT
#define YY_INPUT(buf,result,max_size) \
	if ( (result = fread( (char*)buf, sizeof(char), max_size, fin)) < 0) \
		YY_FATAL_ERROR( "read() in flex scanner failed");

char string_buf[MAX_STR_CONST]; /* to assemble STRING constants */
char *string_buf_ptr;

/*
  Define some extra variables
*/
int string_length; // to hold the current length of the string
int comment_depth; // to handle nested comments
int is_broken_string = 0; // to check whether a string contains null characters.

extern int curr_lineno;
extern int verbose_flag;

extern YYSTYPE cool_yylval;

/*
 *  Add Your own definitions here
 */

%}


/*
  Define states for comment and string
*/

%x COMMENT
%x STRING

/*
 * Define regular expressions.
 */


COMMENT_START   "(*"

COMMENT_END   "*)"

STRING_START    "\""

STRING_END    "\""

DARROW    "=>"

LE    "<="

ASSIGN    "<-"

INT_CONST   [0-9]+

/* Starts with a capital letter */
TYPEID 		[A-Z][A-Za-z0-9_]* 

/* Starts with a simple letter */
OBJECTID 	[a-z][A-Za-z0-9_]*

/* Case insensitive regular expressions for keywords */
NEW   (?i:new)

NOT		(?i:not)

CLASS		(?i:class)

ELSE		(?i:else)

IF		(?i:if)

FI		(?i:fi)

IN		(?i:in)

INHERITS	(?i:inherits)

LET		(?i:let)

LOOP		(?i:loop)

POOL		(?i:pool)

THEN		(?i:then)

WHILE		(?i:while)

CASE		(?i:case)

ESAC		(?i:esac)

OF		(?i:of)

ISVOID		(?i:isvoid)

/* first letter of boolean values (true/false) should be simple */
TRUE    t(?i:rue)

FALSE		f(?i:alse)


/*
  Define actions for each regular expression
*/
%%

  /*
  --------------------------------------------------------------- 
                        Handling Keywords
  --------------------------------------------------------------- 
  */
{NEW}	{
  return NEW;
}

{CLASS} {
  return CLASS;
}

{ELSE} {
  return ELSE;
}

{IF} {
  return IF;
}

{FI} {
  return FI;
}

{IN} {
  return IN;
}

{INHERITS} {
  return INHERITS;
}

{LET} {
  return LET;
}

{LOOP} {
  return LOOP;
}

{POOL} {
  return POOL;
}

{THEN} {
  return THEN;
}

{WHILE} {
  return WHILE;
}

{CASE} {
  return CASE;
}

{ESAC} { 
  return ESAC;
}

{OF} {
  return OF;
}

{ISVOID} {
  return ISVOID;
}

{NOT} {
  return NOT;
}


  /*
    Actions for boolean values
  */
{TRUE} {
  // Store 1 inside cool_yyval.boolean
  cool_yylval.boolean = 1;
  // Return BOOL_CONST token
  return BOOL_CONST;
}

{FALSE} {
  // Store 1 inside cool_yyval.boolean
  cool_yylval.boolean = 0;
  // Return BOOL_CONST token
  return BOOL_CONST;
}

  /*
    Action for interger constant
  */
{INT_CONST} {
  // Store the interger value inside cool_yyval.symbol
  cool_yylval.symbol = inttable.add_string(yytext);
  // Return INT_CONST token
  return INT_CONST;
}

  /*
    Action for typeid
  */
{TYPEID} {
  // Store the typeid value inside cool_yyval.symbol
  cool_yylval.symbol = stringtable.add_string(yytext);
  // Return TYPEID token
  return TYPEID;
}

  /*
    Action for objectid
  */
{OBJECTID} {
  // Store the objectid value inside cool_yyval.symbol
  cool_yylval.symbol = stringtable.add_string(yytext);
  // Return OBJECTID token
  return OBJECTID;
}




  /*
    --------------------------------------------------------------- 
                          Handling Comments
    --------------------------------------------------------------- 
  */


  /* Ignore single line comments */
 "--".* {

 }

 /*
  If the current state is INITIAL
 */
<INITIAL>{ 

  /* If the next token is COMMENT_START*/
  {COMMENT_START}	{ 
    // Change state to COMMENT
    BEGIN(COMMENT); 
    // Increment the comment depth by 1
    comment_depth = 1;
  }

  /* If the next token is COMMENT_END */
  {COMMENT_END} { 
    // Set erro_msg in cool_yylval
    cool_yylval.error_msg = "Unmatched *)"; 
    // Return the ERROR token
    return ERROR; 
  }
}




 /*
  If the current state is COMMENT (Inside a comment)
 */
<COMMENT>{
  /* When the next token is another COMMENT_START */
  {COMMENT_START} { 
    // Increment the comment depth by 1
    comment_depth++; 
  }

  /* Ignore anything else*/
  .

  /* If the next token is newline character increment the curr_lineno by 1 */
  \n			{ 
    curr_lineno++; 
  }


  /* If the next token is COMMENT_END */
  {COMMENT_END} 		{ 
    // Decrement comment_depth by 1
    comment_depth--; 

    // If the comment_depth is 0 change the state to INITIAL
    if (comment_depth == 0) { 
      BEGIN(INITIAL); 
    } 
  }

  /* If comes to end of the file */   
  <<EOF>>		{ 
    // change the state to INITIAL
    BEGIN(INITIAL); 
    // Set error message in cool_yyval
    cool_yylval.error_msg = "EOF in comment"; 
    // Return the ERROR token
    return ERROR; 
  }

}



  /*
    --------------------------------------------------------------- 
                          Handling Strings
    --------------------------------------------------------------- 
  */

  /*
    If the current state is INITIAL
  */
<INITIAL>{
  /* If the next token is STRING_START */
  {STRING_START}		{ 
    // Change the current state to STRING
    BEGIN(STRING); 

    // Reset is_broken_string and string_length
    is_broken_string = 0; 
    string_length = 0; 

    // Fill string_buf by null characters
    memset(&string_buf, 0, MAX_STR_CONST); 
  }
}

  /*
    If the current state is STRING (Inside a string)
  */
<STRING>{

  /* If the next token is STRING_END */
  {STRING_END}		{ 
    // Reset the current state to INITIAL
    BEGIN(INITIAL); 

    // Add null character as the last character of string_buf
    string_buf[string_length++] = '\0'; 

    // Check the validity of the length of the string
    if (string_length > MAX_STR_CONST) { 
      cool_yylval.error_msg = "String constant too long"; 
      return ERROR; 
    }

    // If the string is valid (does not contain null characters)
    else if (!is_broken_string) { 
      // Store the string inside cool_yylval.symbol
      cool_yylval.symbol = stringtable.add_string(string_buf); 
      // Return STR_CONST token
      return STR_CONST; 
    }
  } 

    /* If the next token is \" escape character */
  "\\\""		{ 
    // Add " character to string buffer and increment string_length by 1
    string_buf[string_length++] = '"'; 
  }

    /* If the next token is \n escape character (New line character) */
  "\\n"		{ 
    // Add \n character to string buffer and increment string_length by 1
    string_buf[string_length++] = '\n'; 
  }

    /* If the next token is \t escape character (Tab character) */
  "\\t"		{ 
    // Add \t character to string buffer and increment string_length by 1
    string_buf[string_length++] = '\t'; 
  }

    /* If the next token is \f escape character */
  "\\f"		{ 
    // Add \f character to string buffer and increment string_length by 1
    string_buf[string_length++] = '\f'; 
  }
  
    /* If the next token is \b escape character */
  "\\b"		{ 
    // Add \b character to string buffer and increment string_length by 1
    string_buf[string_length++] = '\b'; 
  }

    /* 
      If the next token is line break character in a multiline string. 
      Multiline string can be written using \ character. 
    */
  "\\\n"		{ 
    // Increment line number by 1
    curr_lineno++; 
    // Add new line character to string_buf
    string_buf[string_length++] = '\n'; 
  }

    /* 
      If the next token is "\\", add \ character to string buffer
    */
  "\\\\"		{ 
    string_buf[string_length++] = '\\'; 
  }

    /* 
      If the next token is "\", Ignore it
    */
  "\\"	{ 
     
  }

    /* 
      If the string contains escape null character ('\0') return ERROR token
    */
  "\\\0"  {   
        // Mark the string as a broken string
        is_broken_string = 1;
        cool_yylval.error_msg = "String contains escaped null character.";
        return ERROR;
    }

    /* 
      If the string contains null character return ERROR token
    */
  [\0]		{
      // Mark the string as a broken string
      is_broken_string = 1;
      cool_yylval.error_msg = "String contains null character";
      return ERROR;
  }

    /* 
      If there is a line break (new line character)
    */
  "\n"		{   
        // Increment curr_lineno by 1
        curr_lineno++;
        // Reset state to INITIAL
        BEGIN(INITIAL);

        // If the string is not broken (If the string is broken, it will return an error message from itself. No need to return another error.)
        if (!is_broken_string) {
          // Set error message and return ERROR token
          cool_yylval.error_msg = "Unterminated STRING constant";
          return ERROR;
        }
    }


    
    /* If comes to end of the file */   
  <<EOF>>		{
    // Set error
    cool_yylval.error_msg = "EOF in STRING constant";
               BEGIN(INITIAL);
    // Return ERROR state 
    return ERROR;
  }

    /* For any other character */
  .		{ 
    // Store character inside string buffer
    string_buf[string_length++] = *yytext; 
  }	
}



  /*
    --------------------------------------------------------------- 
                      Multiple Character Operators
    --------------------------------------------------------------- 
  */
  {DARROW}		{ 
    return (DARROW); 
  }

  {LE} {
    return LE;
  }

  {ASSIGN} {
    return ASSIGN;
  }


 /*
    For follwoing tokens return the escape character of itselves.
  */

  "."	{ return (int)'.'; }
  ";"	{ return (int)';'; }
  ","	{ return (int)','; }
  ")"	{ return (int)')'; }
  "("	{ return (int)'('; }
  "}"	{ return (int)'}'; }
  "{"	{ return (int)'{'; }
  "<"	{ return (int)'<'; }
  ":"	{ return (int)':'; }
  "="	{ return (int)'='; }
  "+"	{ return (int)'+'; }
  "-"	{ return (int)'-'; }
  "*"	{ return (int)'*'; }
  "/"	{ return (int)'/'; }
  "~"	{ return (int)'~'; }
  "@"	{ return (int)'@'; }

  /* Ignore spaces, tab spaces, \f, \v, \r characters */
\t|" "|\f|\v|\r

  /* For new line character increment curr_lineno by 1 */
\n	{ curr_lineno++; }

  /* If the next token did not match for any regular expression return ERROR token */
.	{ cool_yylval.error_msg = strdup(yytext); return ERROR; }


%%
