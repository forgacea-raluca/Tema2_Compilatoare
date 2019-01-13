%code requires{
	#include <list>
}

%{
	#include <stdio.h>
        #include <string.h>
	#include <list>
	
	int yylex();
	int yyerror(const char *msg);

	int EsteCorecta = 1;
	char msg[500];

	class TVAR
	{
	  public:
	     char* nume;
	     int valoare;
	     TVAR* next;
	  
	  public:
	     static TVAR* head;
	     static TVAR* tail;

	     TVAR(char* n, int v = -1);
	     TVAR();
	     int exists(char* n);
             void add(char* n, int v = -1);
             int getValue(char* n);
	     void setValue(char* n, int v);
	};

	TVAR* TVAR::head;
	TVAR* TVAR::tail;

	TVAR::TVAR(char* n, int v)
	{
	 this->nume = new char[strlen(n)+1];
	 strcpy(this->nume,n);
	 this->valoare = v;
	 this->next = NULL;
	}

	TVAR::TVAR()
	{
	  TVAR::head = NULL;
	  TVAR::tail = NULL;
	}

	int TVAR::exists(char* n)
	{
	  TVAR* tmp = TVAR::head;
	  while(tmp != NULL)
	  {
	    if(strcmp(tmp->nume,n) == 0)
	      return 1;
            tmp = tmp->next;
	  }
	  return 0;
	 }

         void TVAR::add(char* n, int v)
	 {
	   TVAR* elem = new TVAR(n, v);
	   if(head == NULL)
	   {
	     TVAR::head = TVAR::tail = elem;
	   }
	   else
	   {
	     TVAR::tail->next = elem;
	     TVAR::tail = elem;
	   }
	 }

         int TVAR::getValue(char* n)
	 {
	   TVAR* tmp = TVAR::head;
	   while(tmp != NULL)
	   {
	     if(strcmp(tmp->nume,n) == 0)
	      return tmp->valoare;
	     tmp = tmp->next;
	   }
	   return -1;
	  }

	  void TVAR::setValue(char* n, int v)
	  {
	    TVAR* tmp = TVAR::head;
	    while(tmp != NULL)
	    {
	      if(strcmp(tmp->nume,n) == 0)
	      {
		tmp->valoare = v;
	      }
	      tmp = tmp->next;
	    }
	  }

	TVAR* ts = NULL;

int Initialized(char* var);    
int Declared(char* var);
int WasDeclaredBefore(char* var);

%}



%union  { 
	   std::list<char*> *idlist = NULL;
	   char* sir;
	   int val;
	}

%type <idlist> id_list
%token 	TOK_EGAL TOK_PLUS TOK_MINUS TOK_MULTIPLY TOK_DIVIDE TOK_LEFT TOK_RIGHT TOK_ERROR
%token TOK_PROGRAM TOK_VAR TOK_BEGIN TOK_END TOK_INTEGER TOK_READ TOK_WRITE TOK_FOR TOK_DO TOK_TO

%token <sir> TOK_ID
%token <val> TOK_INT

%locations

%start prog

%left TOK_PLUS TOK_MINUS
%left TOK_MULTIPLY TOK_DIVIDE

%%

prog : 
	|
	TOK_PROGRAM prog_name TOK_VAR dec_list TOK_BEGIN stmt_list TOK_END'.'
	|
	error ';' prog
	   { EsteCorecta = 0; }

	;
prog_name: TOK_ID
	   ;
	
dec_list:  dec
	   |
	   dec_list';' dec
	   ;

dec:	   id_list':' type
	   {	

		for (auto it = $1->begin(); it != $1->end(); it++)
		{
			if (WasDeclaredBefore(*(it)))
				;
		}
	
	   }
	   ;

type:	   TOK_INTEGER
	   ;

id_list:   TOK_ID
	{
	   $$ = new std::list<char*>();
	   $$->push_back($1);
	}
	   |

	   id_list',' TOK_ID
	{
	   $$->push_back($3);
	}
	   ;	

stmt_list: stmt
	   |  
	   stmt_list';' stmt
	   ;

stmt:	   assign
	   |
	   read
	   |
	   write
	   |
  	   for
	   ;

assign:    TOK_ID TOK_EGAL exp
         {
	   if (Declared($1))
		;	
         }
	   ;

exp:	   term
	   |
	   exp TOK_PLUS term
	   |
	   exp TOK_MINUS term
	   ;

term:	   factor
	   |
	   term TOK_MULTIPLY factor
	   |
	   term TOK_DIVIDE factor
	   ;

factor:	   TOK_ID
	  {
	   if (Initialized($1))
			;
	
	  }
	   |
	   TOK_INT
	   |
	   TOK_LEFT exp TOK_RIGHT
	   ;

read:	   TOK_READ TOK_LEFT id_list TOK_RIGHT
	   {
		for (auto it = $3->begin(); it != $3->end(); it++)
		{
			if(Declared(*(it)))
				;
		}

           }
	   ;

write:	   TOK_WRITE TOK_LEFT id_list TOK_RIGHT
	   {
		for (auto it = $3->begin(); it != $3->end(); it++)
		{
			if (Declared(*(it)))
				;
			if (Initialized(*(it)))
				;
		}
	   }
	   ;

for:	   TOK_FOR index_exp TOK_DO body
	   ;

index_exp: TOK_ID TOK_EGAL exp TOK_TO exp
           {
	       if (Declared($1))
		;
           }
	   ;

body:	   stmt
	   |
	   TOK_BEGIN stmt_list TOK_END
	   ;
%%

int main()
{
     try
     {
 	yyparse();
     }
     catch(char c)
     {
       printf("Eroare lexicala: Atomul lexical %c nu potriveste nicio expresie regulara!!\n",c);
	return 0;
     }

	if(EsteCorecta == 1)
	{
		printf("Propozitie corecta\n");
	}
	
		return 0;
}

int yyerror( const char *msg)
{
	printf("Eroare: %s\n", msg);
	return 0;
}

int WasDeclaredBefore(char* var)
{
	if(ts != NULL)
	{
	  if(ts->exists(var) == 0)
	  {
	    ts->add(var);
	  }
	  else
	  {
	    sprintf(msg,"%d:%d Eroare semantica: Declaratii multiple pentru variabila %s!", yylloc.first_line, yylloc.first_column, var);
	    yyerror(msg);
	    return -1;
	  }
	}
	else
	{
	  ts = new TVAR();
	  ts->add(var);
	}
	return 0;
}

int Declared(char* var)
{
	if(ts != NULL)
	{
	  if(ts->exists(var) == 1)
	  {
	    ts->setValue(var, 1);
	  }
	  else
	  {
	    sprintf(msg,"%d:%d Eroare semantica: Variabila %s este utilizata fara sa fi fost declarata!", yylloc.first_line, yylloc.first_column, var);
	    yyerror(msg);
	    
	    return -1;
	  }
	}
	else
	{
	  sprintf(msg,"%d:%d Eroare semantica: Variabila %s este utilizata fara sa fi fost declarata!", yylloc.first_line, yylloc.first_column, var);
	  yyerror(msg);
	  return -1;
	}
	return 0;
}

int Initialized(char* var)
{
	if(ts != NULL)
	{
	  if(ts->exists(var) == 1)
	  {
	    if(ts->getValue(var) == -1)
	    {
	      sprintf(msg,"%d:%d Eroare semantica: Variabila %s este utilizata fara sa fi fost initializata!", yylloc.first_line, yylloc.first_column, var);
	      yyerror(msg);
	      return -1;
	    }
	  }
	  else
	  {
	    sprintf(msg,"%d:%d Eroare semantica: Variabila %s este utilizata fara sa fi fost declarata!", yylloc.first_line, yylloc.first_column, var);
	    yyerror(msg);
	    return -1;
	  }
	}
	else
	{
	  sprintf(msg,"%d:%d Eroare semantica: Variabila %s este utilizata fara sa fi fost declarata!", yylloc.first_line, yylloc.first_column, var);
	  yyerror(msg);
	  return -1;
	}
	return 0;
}

