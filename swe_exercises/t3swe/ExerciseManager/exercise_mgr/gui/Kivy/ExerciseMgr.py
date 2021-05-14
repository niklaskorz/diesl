import os
import sys
from functools import partial
from pathlib import Path

sys.path.append(str(Path(__file__).absolute().parents[3]))

import kivy
from kivy.app import App
from kivy.config import Config
from kivy.properties import BooleanProperty
from kivy.uix.floatlayout import FloatLayout
from kivy.uix.gridlayout import GridLayout
from kivy.uix.scrollview import ScrollView

from exercise_mgr.gui.Kivy.data import Exercise
from exercise_mgr.gui.Kivy.utils_gui import *

kivy.require('1.11.1')
Config.set('input', 'mouse', 'mouse,multitouch_on_demand')


class RootWidget(BoxLayout):
    pass


class RetractFilter(FloatLayout):
    retracted = BooleanProperty(None)

    def label_change(self, state):
        if state:
            self.btn.text = '->'
        else:
            self.btn.text = '<-'


class RetractExit(BoxLayout):
    retracted = BooleanProperty(None)

    def label_change(self, state):
        if state:
            self.btn.text = '<-'
        else:
            self.btn.text = '->'


class FilterController(GridLayout):

    def __init__(self, **kwargs):
        """
        populates the filter area on the left. Buttons and Widgets are generated dynamically from Data from Database
        which is why I add all the Widgets here in code instead of using the Kv-file which gives a better overview but
        makes it hard to generate Widgets dynamically.
        :param kwargs:
        """
        self.selected_exercise_descriptive_filteroptions = []
        database = Settings.database
        conn = s.create_connection(database)
        self.exercise_descriptive_filteroptions = s.get_exercise_describtive_filteroptions(conn)
        self.subtopics = s.get_subtopics(conn)
        self.parent_topics = s.get_parent_topics(conn)
        self.button_count = 0  # needed to read children without buttons

        super(FilterController, self).__init__(**kwargs)
        filter_layout = BoxLayout(orientation='vertical', size_hint_y=None, pos_hint={"top": 1})

        #  create all the Spinner-selectors for Topic-filters
        for parent_topic in self.parent_topics:
            subtopics = self.subtopics[parent_topic]
            self.topic_dropdown = TopicMultiSelectSpinner(values=subtopics, size_hint_y=None, height=30,
                                                          text=parent_topic, background_color=[0.3, 0.5, 0.8, 0.5])
            filter_layout.add_widget(self.topic_dropdown)

        #  creates the Dropdown for the year/Semester filter
        self.semester = SemesterDropdown()
        self.mainbutton = Button(text='not used since', size_hint=(1, None), height=30)
        self.button_count += 1
        self.mainbutton.bind(on_release=self.semester.open)
        self.semester.bind(on_select=partial(FilterController.on_select_date, self))

        #  creates Toggle Buttons for "exercise descriptive filters" like "Rechenaufgabe"
        for exercise_descriptive_filteroption in self.exercise_descriptive_filteroptions:
            b = ToggleButton(text=exercise_descriptive_filteroption, size_hint_y=None, height=30)
            b.bind(state=self.save_selection_and_apply)
            self.button_count += 1
            filter_layout.add_widget(b)
        filter_layout.add_widget(self.mainbutton)

        filter_layout.bind(minimum_height=filter_layout.setter('height'))
        self.add_widget(filter_layout)

    def save_selection_and_apply(self, instance, value):
        """
        saves changes to toggle-buttons for exercise descriptive filteroptions (e.g Rechenaufgabe) calls function to
        apply changes and load items according to filter
        :param instance: references pressed toggle-button
        :param value: state of toggle-button
        :return:
        """
        if value == 'down':
            self.selected_exercise_descriptive_filteroptions.append(instance.text)
        else:
            self.selected_exercise_descriptive_filteroptions.remove(instance.text)
        self.apply_filter()

    #  TODO unused variable
    def on_select_date(self, filterlayout, x):
        """
        triggered if semester/year is selected, call apply_filter
        :param filterlayout:
        :param x:
        :return:
        """
        setattr(self.mainbutton, 'text', x)
        self.apply_filter()

    def retract(self):
        self.visible = not self.visible

    def apply_filter(self):
        """
        collects selections, sets defaults if there are none and calls function to update view based on selections
        :return:
        """
        topics_selected = []

        #  reads all selected topics von all topic-spinners
        items_in_filtercontroller = self.children[0].children
        at_least_1_item_selected = False
        length = len(items_in_filtercontroller)
        for TopicMultiSelectSpinner_index in range(self.button_count, length):
            topic_multi_select_spinner = items_in_filtercontroller[TopicMultiSelectSpinner_index]
            if topic_multi_select_spinner.selected_values:
                at_least_1_item_selected = True
            temp = topic_multi_select_spinner.selected_values
            topics_selected.extend(temp)

        #  reads selected semester
        semester_selected = self.mainbutton.text

        #  sets defaults so that all Exercises are shown if nothing is selected
        if len(semester_selected) > 4:  # falls keine Auswahl getroffen wurde wird aktuelles Datum eingestellt
            now = datetime.datetime.now()
            semester_selected = str(now.year)
        if not at_least_1_item_selected:  # with no selection no filter will be applied
            conn = s.create_connection(Settings.database)
            topics_selected = s.get_topics(conn)

        #  sets filter and updates view
        exercise_layout = self.parent.children[1]
        myfilter = (topics_selected, semester_selected, self.selected_exercise_descriptive_filteroptions)
        ExerciseLayout.set_filter(exercise_layout, myfilter)
        ExerciseLayout.update(exercise_layout)


class ExerciseLayout(ScrollView):

    def __init__(self, **kwargs):
        """
        initializes main view with all the exercises with default values
        :param kwargs: 
        """
        super(ExerciseLayout, self).__init__(**kwargs)
        self.database = Settings.database

        self.layout = BoxLayout(orientation='vertical', size_hint_y=None)
        self.add_widget(self.layout)
        self.layout.bind(minimum_height=self.layout.setter('height'))

        #  makes default selections on what to show when app is started
        conn = s.create_connection(self.database)
        topics = s.get_topics(conn)
        now = datetime.datetime.now()
        self.selected_filter = [topics, str(now.year), []]
        self.exercise_data = []
        self.pages = 0
        self.current_page = 1
        self.items_per_page = Settings.items_per_page

        #  loads default selections
        self.apply_filter()
        self.load_page_x(1)

    def set_data(self, data_array):
        self.exercise_data = data_array

    def set_filter(self, selected_filter):
        self.selected_filter = selected_filter

    def get_database(self):
        return self.database

    def apply_filter(self):
        conn = s.create_connection(self.database)
        self.exercise_data = s.get_filter_matching_exercises(conn, self.selected_filter)

    def update(self):
        self.apply_filter()
        self.load_page_x(1)

    def load_page_x(self, x):
        """
        clears all widgets from Exercise_Layout, creates a pagebar and creates new OneScrollItems from requested page x
        out of exercise data. Places Settings.items_per_page items per page
        Decided not to outsource this part (even though it looks like logic) because it basically only populates the
        view and needs to access and add a lot of data in this class
        :param x: number of page to load
        :return:
        """
        self.layout.clear_widgets()
        self.pages = len(self.exercise_data) // self.items_per_page + 1
        self.current_page = x

        # creates and adds Pagebar
        page_bar = PageBar(self.pages, self.current_page, orientation='horizontal', height=20, size_hint_y=None)
        self.layout.add_widget(page_bar)

        #  if x is not the last page load/create a full page
        if x < self.pages:  # 2 if statements to avoid try catch (crashes on last not full page otherwise)
            x = x - 1  # to avoid a 0th page and have pages start at 1
            for exercise_index in range(x * self.items_per_page, (x + 1) * self.items_per_page):
                one_scroll_entry = OneScrollItem(self.exercise_data[exercise_index], self.layout, size_hint_y=None)
                self.layout.add_widget(one_scroll_entry)
        # if x is the last page load/create only the rest
        if x == self.pages:
            x = x - 1
            rest = len(self.exercise_data) % self.items_per_page
            for exercise_index in range(x * self.items_per_page, x * self.items_per_page + rest):
                one_scroll_entry = OneScrollItem(self.exercise_data[exercise_index], self.layout, size_hint_y=None)
                self.layout.add_widget(one_scroll_entry)

    def load_onescrollitems(self, x, data_scrollitems):
        """
        similar to previous function "load_page_x" but with small adjustments because this function is used to load
        items from Exitlayout if "preview all" is selected, is its own function to avoid flag arguments
        Decided not to outsource this part (even though it looks like logic) because it basically only populates the
        view and needs to access and add a lot of data in this class
        :param x: (int)number of page to be loaded
        :param data_scrollitems: (list) of OneScrollItems
        :return:
        """
        self.layout.clear_widgets()
        self.pages = len(data_scrollitems) // self.items_per_page + 1
        self.current_page = x

        # creates and adds Pagebar
        page_bar = PageBar(self.pages, self.current_page, orientation='horizontal', height=20, size_hint_y=None)
        self.layout.add_widget(page_bar)

        #  if x is not the last page load/create a full page
        if x < self.pages:  # 2 if statements to avoid try catch (crashes on last not full page otherwise)
            x = x - 1  # to avoid a 0th page and have pages start at 1
            for exercise_index in range(x * self.items_per_page, (x + 1) * self.items_per_page):
                self.layout.add_widget(data_scrollitems[exercise_index])
        # if x is the last page load/create only the rest
        if x == self.pages:
            x = x - 1
            rest = len(data_scrollitems) % self.items_per_page
            for exercise_index in range(x * self.items_per_page, x * self.items_per_page + rest):
                self.layout.add_widget(data_scrollitems[exercise_index])


class ExitLayout(GridLayout):

    def __init__(self, **kwargs):
        super(ExitLayout, self).__init__(**kwargs)
        self.button_count = -1  # -1 for not yet calculated
        self.header_array = []
        self.popup_window = -1

    def get_current_popup(self):
        return self.popup_window

    def add_item(self, item):
        """
        creates and adds OneArrangementItem to Exitlayout.
        Since all widgets created with kv-file are not yet created while __init__ runs the number of buttons created in
        the kv file is saved here.
        Number needed to determine allowed positions of OneArrangementItems
        :param item: OneScrollItem
        :return:
        """
        if self.button_count == -1:
            self.button_count = len(self.children)
        self.add_widget(OneArrangementItem(item))

    def retract(self):
        self.visible = not self.visible

    def on_create_pdf(self):
        """
        concatenate the content of all OneArrangementItems in Exitlayout in the order they are displayed there. Then
        creates pdf, latex and log file and saves that to path below
        :return:
        """

        path1 = Settings.save_path
        path1.mkdir(exist_ok=True)
        path2 = path1 / "problem_set.tex"

        f = open(path2, "w+", encoding='utf-8')

        exercise_text_ids = []
        #  widgets on top have the highest index so reverse it to get displayed order
        if self.button_count != -1:  # -1 means no item has been added so nothing to create here
            for onearrangementitem_index in reversed(range(len(self.children) - self.button_count)):
                one_arrange_temp = self.children[onearrangementitem_index]
                index_to_display = one_arrange_temp.get_index_displayed_item_of_family()
                exercise = one_arrange_temp.get_exercises_of_family()[index_to_display]
                # append for later use
                exercise_text_ids.append(exercise.get_exercise_text_id())
                content = exercise.get_exercise_content()
                f.writelines(content)
            f.write('\\end{document}')
            f.close()
            os.system(f'pdflatex -interaction nonstopmode -output-directory={path1} {path2} ')

            show = ProblemSetPopup(exercise_text_ids, self)
            self.popup_window = Popup(title="Enter number of problem set",
                                      content=show, size_hint=(None, None), size=(300, 160))
            self.popup_window.open()

    def on_preview_all(self):
        """
        collects all OneArrangementItems in the Order displayed and calls function to display them in exerciselayout
        :return:
        """
        preview_array = []
        preview_array2 = []
        #  widgets on top have the highest index so reverse it to get displayed order
        if self.button_count != -1:  # -1 means no item has been added so nothing to preview
            for onearrangementitem_index in reversed(range(len(self.children) - self.button_count)):
                preview_array.append(self.children[onearrangementitem_index].get_exercises_of_family())
                preview_array2.append(self.children[onearrangementitem_index].get_matching_scroll_item())
            exercise_layout = self.parent.children[1]
            exercise_layout.load_onescrollitems(1, preview_array2)

    def on_edit_header(self):
        """
        gets all headers from database and creates Exercises out of them. Calls function to display them in
        exerciselayout
        :return:
        """
        database = Settings.database
        conn = s.create_connection(database)
        array = s.get_my_header(conn)
        # creates new empty header if no header exists
        if len(array) == 0:
            conn = s.create_connection(database)
            s.save_new_empty_header(conn)
            conn = s.create_connection(database)
            array = s.get_my_header(conn)
        self.header_array = []
        for el in array:
            self.header_array.append(Exercise([el[0], el[1], el[2], el[3], "header", -1, -1]))
        exercise_layout = self.parent.children[1]
        exercise_layout.set_data([self.header_array])
        exercise_layout.load_page_x(1)


class ExerciseMgrApp(App):
    pass


if __name__ == '__main__':
    ExerciseMgrApp().run()
