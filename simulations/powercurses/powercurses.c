#include <stdio.h>
#include <stdlib.h>
#include <curses.h>
#include <strings.h>

enum batterystatus { GOODBATTERY = 1, MIDBATTERY, LOWBATTERY };

struct mote_state {
    float       battery_state;
    int         mote_num;    
    WINDOW      *mote;
};


#define         STARTX  1
#define         STARTY  1
#define         HEIGHT  3   
#define         WIDTH   32


WINDOW *create_info(int,int,int,int);
struct mote_state *create_newwin(int,int,int,int,int,int);
void update_win(struct mote_state *, float);
void update_info(WINDOW *, float);
extern char *strarg( const char *, const char *, size_t );


int main (int argc, char **argv)
{
    /*
     * This is actually ugly, we are going to move that static allocation in a dinamic one based on 
     * the number of motes...
     */

    struct mote_state  *win[100];  
    int     ch;
    int     i = 0;
    int     num_motes = 0;
    WINDOW  *info_win;
    char    inputline[255];


    if ( argc != 2 )
    {
        fprintf(stderr, "Usage : %s numberofmotes\n");
        exit(EXIT_FAILURE);
    }

    num_motes = atoi(argv[1]);
    num_motes++;

    initscr();
    cbreak();

    if(has_colors() == FALSE)
    {   endwin();
        printf("Your terminal does not support color\n");
        exit(1);
    }

    start_color();
    init_pair(GOODBATTERY, COLOR_WHITE, COLOR_BLACK);
    init_pair(MIDBATTERY, COLOR_GREEN, COLOR_BLACK);
    init_pair(LOWBATTERY, COLOR_RED, COLOR_BLACK);    


    keypad(stdscr, TRUE); 


    refresh();

    info_win = create_info(4,38,20,28 * 3);

    for ( i = 0 ; i < num_motes; i++ ) { 
        win[i] = create_newwin(i,HEIGHT,WIDTH,1,1,num_motes);
    }

    bzero(inputline, 255);

    while ( fgets(inputline, 255, stdin) != NULL ) 
    {
        if ( strncmp(strarg(inputline, ",", 1), "POWERCURSES", 11) )
            continue;

        update_info(info_win, atof(strarg(inputline, ",",2)));
        
        int mote_num = atoi(strarg(inputline,",",3));

        update_win(win[mote_num], atof(strarg(inputline, ",",4)));
        bzero(inputline, 255);
    }

	while (getchar());

       
    endwin();
    return EXIT_SUCCESS;

}



struct mote_state *create_newwin(int mote, int height, int width, int starty, int startx, int num_motes)
{   
    struct mote_state *dest;
    WINDOW *local_win;
    int     i   = 0;

    dest = malloc(sizeof *dest);

    dest->mote_num = mote;
    dest->battery_state = 100;

    if ( mote < num_motes/2 )
        local_win = newwin(height, width, starty + 3 *  mote, startx);
    else
        local_win = newwin(height, width, starty + 3 * (mote - num_motes/2), startx + 40);

    dest->mote = local_win;
    return dest;

}

void update_win(struct mote_state *m, float batstate)
{
    WINDOW *local_win = m->mote;
    int i = 0;
 
    m->battery_state = batstate;

    box(local_win, 0, 0);
    
    wattron(local_win, COLOR_PAIR(GOODBATTERY));
    mvwprintw(local_win,STARTY, STARTX + 1, "MOTE : %d ", m->mote_num);
    wattroff(local_win, COLOR_PAIR(GOODBATTERY));

    wrefresh(local_win);

   
    if ( m->battery_state/10 > 5 )  {
    for ( i = 0; i < m->battery_state/10; i++ )
        waddch(local_win, ACS_BLOCK | COLOR_PAIR(MIDBATTERY));
    } else {
        for ( i = 0; i < m->battery_state/10; i++ )
        waddch(local_win, ACS_BLOCK | COLOR_PAIR(LOWBATTERY));
    }
    

    wprintw(local_win, "  %.2f %", m->battery_state);

    wrefresh(local_win);

}


WINDOW *create_info(int height, int width, int starty, int startx)
{
    WINDOW *local_win;
    int     i   = 0;

    local_win = newwin(height, width, starty , startx );
   
    return local_win;
} 

void update_info(WINDOW *local_win, float time)
{
    box(local_win, 0 , 0);
    wrefresh(local_win);
    wattron(local_win, COLOR_PAIR(GOODBATTERY));
    mvwprintw(local_win,STARTY, STARTX+1, "Simulation time : %f secs", time);
    // mvwprintw(local_win,STARTY+1, STARTX+1, "Program running...");
    wattroff(local_win, COLOR_PAIR(GOODBATTERY));

    wrefresh(local_win);

}


