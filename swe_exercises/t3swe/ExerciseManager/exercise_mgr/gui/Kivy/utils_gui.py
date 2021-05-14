import datetime

from exercise_mgr.Settings import Settings
from kivy.properties import ListProperty, ObjectProperty
from kivy.uix.boxlayout import BoxLayout
from kivy.uix.button import Button
from kivy.uix.dropdown import DropDown
from kivy.uix.popup import Popup
from kivy.uix.togglebutton import ToggleButton

import exercise_mgr.database.sqlite_wrapper as s


class MultiSelectSpinner(Button):
    """Widget allowing to select multiple text options."""

    dropdown = ObjectProperty(None)

    """(internal) DropDown used with TopicMultiSelectSpinner."""

    values = ListProperty([])
    """Values to choose from."""

    selected_values = ListProperty([])
    """List of values selected by the user."""

    def __init__(self, **kwargs):
        self.change_made = 0
        self.bind(dropdown=self.update_dropdown)
        self.bind(values=self.update_dropdown)
        super(MultiSelectSpinner, self).__init__(**kwargs)
        self.bind(on_release=self.toggle_dropdown)

    def toggle_dropdown(self, *args):
        if self.dropdown.parent:
            self.dropdown.dismiss()
        else:
            self.dropdown.open(self)

    def on_dismiss(self, x):
        pass

    def update_dropdown(self, *args):
        if not self.dropdown:
            self.dropdown = DropDown()
            self.dropdown.bind(on_dismiss=lambda x: self.on_dismiss(x))
        values = self.values
        if values:
            if self.dropdown.children:
                self.dropdown.clear_widgets()
            for value in values:
                b = ToggleButton(text=value, size_hint_y=None, height=30)
                b.bind(state=self.select_value)
                self.dropdown.add_widget(b)

    def select_value(self, instance, value):
        if value == 'down':
            if instance.text not in self.selected_values:
                self.selected_values.append(instance.text)
        else:
            if instance.text in self.selected_values:
                self.selected_values.remove(instance.text)
        self.change_made = 1


class TopicMultiSelectSpinner(MultiSelectSpinner):
    """
    MultiSelectSpinner adjusted for topic selection in filter-layout by calling function to apply and update view if
    something is selected and changing the colour of spinner-button to indicate something is selected
    """

    def select_value(self, instance, value):
        if value == 'down':
            if instance.text not in self.selected_values:
                self.selected_values.append(instance.text)
        else:
            if instance.text in self.selected_values:
                self.selected_values.remove(instance.text)
        filtercontroller = self.parent.parent
        filtercontroller.apply_filter()
        if self.selected_values:
            self.background_color = [1, 0.5, 0.5, 0.5]
        else:
            self.background_color = [0.3, 0.5, 0.8, 0.5]


class PopupMultiSelectSpinner(MultiSelectSpinner):
    """
    MultiSelectSpinner adjusted for being used in a popup by auto-select all values given by database to show what is
    already selected and calling a function to collect changes only if we popup is dismissed
    """

    def on_dismiss(self, x):
        if self.change_made == 1:
            self.parent.collect_changes()
            self.change_made = 0

    def update_dropdown(self, *args):
        if not self.dropdown:
            self.dropdown = DropDown()
            self.dropdown.bind(on_dismiss=lambda x: self.on_dismiss(x))
        values = self.values
        selected_values = self.selected_values
        if values:
            if self.dropdown.children:
                self.dropdown.clear_widgets()
            for value in values:
                b = ToggleButton(text=value, size_hint_y=None, height=30)
                b.bind(state=self.select_value)
                if b.text in selected_values:
                    b.state = "down"
                self.dropdown.add_widget(b)


class SemesterDropdown(DropDown):
    """
    custom dropdown to collect semester. uses datetime to always have the current year as option
    """

    def __init__(self, **kwargs):
        super(SemesterDropdown, self).__init__(**kwargs)

        now = datetime.datetime.now()
        for year in range(now.year, now.year - Settings.years_to_go_back, -1):
            btn = Button(text=f'{year}', size_hint_y=None, height=30)
            btn.bind(on_release=lambda btn: self.select(btn.text))
            self.add_widget(btn)


class ProblemSetPopup(BoxLayout):

    def __init__(self, exercise_text_ids, in_layout):
        self.in_layout = in_layout
        self.exercise_text_ids = exercise_text_ids
        self.font_size = 20
        super(BoxLayout, self).__init__()

    def on_not_add_to_database(self):
        self.in_layout.get_current_popup().dismiss()

    def on_add_to_database(self):
        # saves exercise with new name to database
        number_problem_set = self.ids["number_problem_set"].text
        number_problem_set = int(number_problem_set)
        database = Settings.database
        conn = s.create_connection(database)
        now = datetime.datetime.now()
        semester = str(now.year)
        semester = int(semester[-2::])
        problem_set_id = s.problem_set_insert(conn, [None, None, None, 1, number_problem_set, semester])
        exercise_num = 1
        points = 0
        for exercise_text_id in self.exercise_text_ids:
            exercise_to_problem_set = (exercise_text_id, problem_set_id, exercise_num, points)
            s.exercise_to_problem_set_insert(conn, exercise_to_problem_set)
            exercise_num += 1

        conn.commit()
        conn.close()

        # closes popup
        self.in_layout.get_current_popup().dismiss()


class NamePopup(BoxLayout):
    """
    Popup to collect exercise name after "save" button in OneScrollItem. Note that in_layout is the layout that this
    popup is created in. The reason here to pass it as argument is that I could not find a way to close the popup from
    within the popup.
    """

    def __init__(self, exercise_name, text_in_exercise_text_box, exercise_family_id, in_layout):
        self.in_layout = in_layout
        self.exercise_name = exercise_name
        self.text_in_exercise_text_box = text_in_exercise_text_box
        self.exercise_family_id = exercise_family_id
        self.font_size = 30
        super(BoxLayout, self).__init__()

    def on_save(self):
        # saves exercise with new name to database
        chosen_name = self.ids["name_text"].text
        database = Settings.database
        conn = s.create_connection(database)
        s.create_new_exercise(conn, [chosen_name, self.text_in_exercise_text_box], self.exercise_family_id)

        conn.commit()
        conn.close()

        # closes popup
        self.in_layout.get_current_popup().dismiss()

        # refreshes view so new item is shown
        exercise_layout = self.in_layout.parent.parent.parent.children[1]
        exercise_layout.update()



class EditPopup(BoxLayout):
    """
    custom popup window to collect topic and exercise descriptive filter option
    """
    def __init__(self, exercise_id, exercise_fam_id, in_layout):
        self.in_layout = in_layout # kivy gives you a hard time closing the popup from within the popup and this helps
        self.exercise_id = exercise_id
        self.exercise_fam_id = exercise_fam_id
        self.selected_topics = []
        self.selected_descriptive_filteroptions = []
        self.font_size = 20
        self.database = Settings.database
        conn = s.create_connection(self.database)
        self.start_value = s.get_topics_of_exercise_fam(conn, exercise_fam_id)
        self.start_descriptive_value = s.get_descriptive_filteroption_of_exercise_fam(conn, exercise_fam_id)
        self.descriptive_filteroptions = list(s.get_exercise_describtive_filteroptions(conn))
        self.topics = list(s.get_topics(conn))
        super(BoxLayout, self).__init__()

    def collect_changes(self):
        self.selected_topics = self.ids["topic_spinner"].selected_values
        self.selected_descriptive_filteroptions = self.ids["descriptive_spinner"].selected_values

    def on_save(self):
        self.collect_changes()
        conn = s.create_connection(self.database)
        s.update_via_popup(self.exercise_fam_id, self.selected_topics,
                           self.selected_descriptive_filteroptions, conn)
        self.in_layout.get_current_popup().dismiss()


class PageBar(BoxLayout):
    """
    Custom page bar that creates as many buttons with ascending numbers as requested
    """

    def __init__(self, pages, current_page, **kvargs):
        super(PageBar, self).__init__(**kvargs)
        for i in range(1, pages + 1):
            btn = Button(text=f'{i}')
            if i == current_page:
                btn.background_color = (.2, .1, .73, 1)
            btn.bind(on_press=self.on_page_button_press)
            self.add_widget(btn)

    def on_page_button_press(instance, value):
        exercise_layout = instance.parent.parent
        page_to_go = int(value.text)
        exercise_layout.load_page_x(page_to_go)


class OneScrollItem(BoxLayout):
    """
    Item that the ScrollView in exercise layout is populated with hence the name OneScrollItem. It has a TextInput and
    several buttons that allow you to make changes to the exercise and save that etc.
    """

    def __init__(self, exercises_of_family, layout, fam_index=0, **kvargs):
        """
        :param exercise: list of Exercise-instances that belong to one exercise family
        :param layout: layout this item will be placed in, needed so that this item can delete itself if button pressed
        :param fam_index: (int) index of which Exercise from (list) exercise should be displayed
        :param kvargs:
        """
        self.popup_window = 0  # helps dealing with closing the popup

        self.database = Settings.database
        self.family_index_displayed = fam_index
        self.layout = layout
        self.exercises_of_family = exercises_of_family
        self.is_in_current_problem_set = 0  # prevents exercise family/ exercise from being added twice to problem set
        self.lines = exercises_of_family[self.family_index_displayed].get_exercise_content().count('\n') + 1
        self.font_size = 20

        super(OneScrollItem, self).__init__(**kvargs)

    def get_exercises_of_family(self):
        return self.exercises_of_family

    def get_family_index_displayed(self):
        return self.family_index_displayed

    def get_current_popup(self):
        return self.popup_window

    def set_is_in_problem_set(self):
        self.is_in_current_problem_set = 1

    def set_is_not_in_problem_set(self):
        self.is_in_current_problem_set = 0

    def update(self):
        """
        updates view TextInput. NOTE: it does not reload the exercise-data from database!
        Shows only a few lines if self.expanded is False and whole exercise text otherwise
        :return:
        """
        test = 0
        if self.expanded:
            current_text = self.children[0].text
            text_to_be = self.exercises_of_family[self.family_index_displayed].get_exercise_content()
            self.children[0].text = self.exercises_of_family[self.family_index_displayed].get_exercise_content()
        else:
            self.children[0].text = self.exercises_of_family[self.family_index_displayed].get_exercise_summary()
        self.children[1].children[7].text = self.exercises_of_family[self.family_index_displayed].get_exercise_name()

    def on_add_to_current_problem_set_button(self):
        if not self.is_in_current_problem_set:
            exit_layout = self.parent.parent.parent.children[0]
            exit_layout.add_item(self)
        self.is_in_current_problem_set = 1

    def on_next_button(self):
        """
        skips to the next exercise of exercise family
        :return:
        """
        new_index = (self.family_index_displayed + 1) % (len(self.exercises_of_family))
        self.family_index_displayed = new_index
        self.update()

    def on_previous_button(self):
        """
        skips to previous exercise of exercise family
        :return:
        """
        new_index = (self.family_index_displayed - 1) % (len(self.exercises_of_family))
        self.family_index_displayed = new_index
        self.update()

    def on_remove_button(self):
        """
        removes displayed exercise from OneScrollItem tree AND calls function to remove exercise from database
        removes OneScrollItem from widget tree if no exercise left to display
        :return:
        """
        exercise_id = self.exercises_of_family[self.family_index_displayed].get_exercise_text_id()
        database = self.database
        conn = s.create_connection(database)
        s.delete_by_id_from_exercise_texts(conn, exercise_id)
        del self.exercises_of_family[self.family_index_displayed]

        if not self.exercises_of_family:
            self.layout.remove_widget(self)
        else:
            self.family_index_displayed = 0
            self.update()

    def on_overwrite_button(self):
        """
        calls function to overwrite changes made in the database. No old version of exercise will be kept
        :return:
        """
        text_in_exercise_text_box = self.children[0].text
        self.exercises_of_family[self.family_index_displayed].set_exercise_content(text_in_exercise_text_box)
        exercise_id = self.exercises_of_family[self.family_index_displayed].get_exercise_text_id()
        database = self.database
        conn = s.create_connection(database)
        s.exercise_texts_overwrite(conn, exercise_id, text_in_exercise_text_box)

    def on_save_button(self):
        """
        opens popup that lets you enter a name and will save the exercise to same exercise_family. Old version will be
        kept
        :return:
        """
        text_in_exercise_text_box = self.children[0].text
        self.exercises_of_family[self.family_index_displayed].set_exercise_content(text_in_exercise_text_box)
        exercise_family_id = self.exercises_of_family[self.family_index_displayed].get_exercise_family_id()
        exercise_name = self.exercises_of_family[self.family_index_displayed].get_exercise_name()
        show = NamePopup(exercise_name, text_in_exercise_text_box, exercise_family_id, self)
        self.popup_window = Popup(title="choose name", content=show, size_hint=(None, None), size=(300, 160))
        self.popup_window.open()

    def on_edit_popup(self):
        """
        Opens a popup in which you can edit properties of the exercise. You can choose which topic an exercise belongs
        to and which exercise descriptive tag they have (e.g. Rechenaufgabe)
        :return:
        """
        exercise_id = self.exercises_of_family[self.family_index_displayed].get_exercise_text_id()
        exercise_fam_id = self.exercises_of_family[self.family_index_displayed].get_exercise_family_id()
        show = EditPopup(exercise_id, exercise_fam_id, self)
        self.popup_window = Popup(title="edit", content=show, size_hint=(None, None), size=(650, 200))
        self.popup_window.open()


class OneArrangementItem(BoxLayout):
    """
    OneArrangementItem is quite similar to OneScrollItem. It takes a OneScrollItem as argument and creates a visual
    representation for the exit layout and allows you to select a position there or remove the item.
    """

    def __init__(self, matching_scroll_item, **kwargs):
        self.matching_scroll_item = matching_scroll_item
        self.index_displayed_item_of_family = matching_scroll_item.get_family_index_displayed()
        exercise = matching_scroll_item.get_exercises_of_family()[self.index_displayed_item_of_family]
        self.exercise_name = exercise.get_exercise_name()
        self.exercises_of_family = matching_scroll_item.get_exercises_of_family()
        super(OneArrangementItem, self).__init__(**kwargs)

    def get_exercises_of_family(self):
        return self.exercises_of_family

    def get_matching_scroll_item(self):
        return self.matching_scroll_item

    def get_index_displayed_item_of_family(self):
        return self.index_displayed_item_of_family

    def on_up_button(self):
        """
        moves representation in exit layout up
        :return:
        """
        exercise_layout = self.parent
        exit_layout = self.parent
        highest_allowed_index = len(exit_layout.children) - 3  # (create, preview, edit_header should not be moved)
        index = get_index_in_list(self.parent.children, self)
        if (index + 1) < highest_allowed_index:
            exercise_layout.remove_widget(self)
            exercise_layout.add_widget(self, index=index + 1)

    def on_down_button(self):
        """
        moves representation in exit layout down
        :return:
        """
        exerciselayout = self.parent
        index = get_index_in_list(self.parent.children, self)
        exit_layout = self.parent
        highest_allowed_index = len(exit_layout.children) - 3
        if ((index - 1) < highest_allowed_index) and index - 1 >= 0:
            exerciselayout.remove_widget(self)
            exerciselayout.add_widget(self, index=index - 1)

    def on_remove_button(self):
        """
        removes representation from exit layout
        :return:
        """
        OneScrollItem.set_is_not_in_problem_set(self.matching_scroll_item)
        exerciselayout = self.parent
        exerciselayout.remove_widget(self)


def get_index_in_list(children, instance):
    index = 0
    for child in children:
        if child == instance:
            return index
        else:
            index += 1

